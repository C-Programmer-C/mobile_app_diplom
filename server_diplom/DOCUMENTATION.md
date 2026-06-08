# Документация функций API

## Сводная таблица маршрутов

Метод | URL | Описание
--- | --- | ---
POST | /auth/register | Регистрация пользователя
POST | /auth/login | Аутентификация и получение access_token
GET | /products | Получение списка товаров
GET | /products/{product_id} | Получение информации о товаре
GET | /products/categories | Получение списка категорий
GET | /cart | Просмотр корзины
POST | /cart/add | Добавление товара в корзину
POST | /cart/set_quantity | Изменение количества товара в корзине
POST | /cart/remove | Удаление товара из корзине
POST | /orders/checkout | Оформление заказа

## 3.2.1. Выполнение функции регистрации и авторизации пользователей

### Регистрация пользователя

Основной эндпоинт для регистрации нового пользователя в системе:

```python
@auth_router.post("/register", summary="Create a new user")
def register(data: RegisterRequest):
    is_exist = create_user(
        data.email,
        data.password,
        data.name,
        phone=data.phone,
    )
    if not is_exist:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="The user already exists"
        )
    return Response(status_code=status.HTTP_201_CREATED)
```

**Описание:** Эндпоинт принимает данные пользователя (email, пароль, имя и номер телефона), проверяет не существует ли уже пользователя с таким email, и создаёт новую учётную запись в базе данных.

#### Подфункция: create_user

```python
def create_user(
    email: str, password: str, name: str, phone: str | None = None
):
    """Create user in database with check existing user"""
    hashed_password = hash_password(password)
    phone_clean = (phone or "").strip()
    with Session(autoflush=False, bind=engine) as db:
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            return False
        new_user = User(
            name=name,
            email=email,
            hashed_password=hashed_password,
            phone=phone_clean if phone_clean else "",
        )
        db.add(new_user)
        db.commit()
        return True
```

**Описание:** Функция выполняет следующие операции:

1. Хеширует пароль для безопасного хранения в БД
2. Проверяет наличие пользователя с таким email
3. При отсутствии пользователя создаёт новый объект User с переданными данными
4. Сохраняет данные в базу данных
5. Возвращает True при успешной регистрации, False если пользователь уже существует

#### Подподфункция: hash_password

```python
def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
```

**Описание:** Функция хеширует пароль с использованием алгоритма bcrypt. Пароль кодируется в UTF-8, хешируется с солью и возвращается в виде строки.

---

### Авторизация пользователя

Основной эндпоинт для авторизации и получения токена доступа:

```python
@auth_router.post("/login", summary="Create access token for user")
def login(data: LoginRequest):
    user = authenticate_user(data.email, data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid email or password"
        )
    return {
        "access_token": create_access_token(user.email),
        "name": user.name,
    }
```

**Описание:** Эндпоинт принимает учётные данные пользователя (email и пароль), проверяет их корректность и при успешной аутентификации возвращает токен доступа и имя пользователя.

#### Подфункция: authenticate_user

```python
def authenticate_user(email: str, password: str) -> None | User:
    with Session(autoflush=False, bind=engine) as db:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user
```

**Описание:** Функция выполняет аутентификацию пользователя:

1. Ищет пользователя в БД по email
2. Проверяет совпадение введённого пароля с хешированным паролем из БД
3. Возвращает объект User при успешной аутентификации, None при ошибке

#### Подподфункция: verify_password

```python
def verify_password(plain_password: str, hashed: str) -> bool:
    """Verify a password against its hash"""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed.encode("utf-8"),
    )
```

**Описание:** Функция проверяет совпадение введённого пароля с его хешированным значением, используя bcrypt. Кодирует оба значения в UTF-8 и возвращает True/False результат.

---

## 3.2.2. Выполнение функции добавления товара в корзину

```python
@cart_router.post("/add", summary="Add product to cart")
def add_to_cart(data: CartItemIn, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    try:
        row = add_product_to_cart_for_user(user, data.product_id, data.quantity)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return {"id": row.id, "product_id": row.product_id, "quantity": row.quantity}
```

**Описание:** Эндпоинт добавляет товар в корзину авторизованного пользователя. Проверяет наличие пользователя и передаёт запрос на добавление товара с указанным количеством.

### Подфункция: add_product_to_cart_for_user

```python
def add_product_to_cart_for_user(
    user: User, product_id: int, quantity: int = 1
) -> Cart:
    if quantity <= 0:
        raise ValueError("quantity must be > 0")

    with Session(autoflush=False, bind=engine) as db:
        product = (
            db.query(Product)
            .filter(Product.id == product_id)
            .with_for_update()
            .first()
        )
        if not product:
            raise ValueError("product not found")
        if product.quantity <= 0:
            raise ValueError("Товар закончился на складе, его нельзя добавить в корзину.")

        cart_row = (
            db.query(Cart)
            .filter(Cart.user_id == user.id, Cart.product_id == product_id)
            .first()
        )

        new_quantity = quantity + (cart_row.quantity if cart_row else 0)
        if new_quantity > product.quantity:
            raise ValueError("Произошла ошибка при увеличении количества товара в корзине. Запрошенное количество превышает доступный запас.")

        if not cart_row:
            cart_row = Cart(user_id=user.id, product_id=product_id, quantity=quantity)
            db.add(cart_row)
        else:
            cart_row.quantity = new_quantity

        db.commit()
        db.refresh(cart_row)
        return cart_row
```

**Описание:** Функция выполняет следующие операции:

1. Проверяет валидность количества (должно быть > 0)
2. Ищет товар в БД по product_id с блокировкой для конкурентного доступа
3. Проверяет наличие товара на складе
4. Ищет существующий элемент корзины для этого пользователя и товара
5. Вычисляет новое количество (добавляет к существующему, если товар уже в корзине)
6. Проверяет, не превышает ли новое количество доступное количество на складе
7. Создаёт новый элемент корзины или обновляет существующий
8. Сохраняет изменения в БД

---

## 3.2.3. Выполнение функции поиска и фильтрации товаров

### Поиск товаров

```python
@product_router.get("/search", summary="Поиск товаров")
def search_products(q: str):
    from database.auth import search_products as db_search_products

    products = db_search_products(q)
    return products
```

**Описание:** Эндпоинт выполняет поиск товаров по строке запроса, ищет совпадения в названиях товаров.

#### Подфункция: search_products

```python
def search_products(query: str):
    """Поиск товаров по названию."""
    with Session(autoflush=False, bind=engine) as db:
        products = db.query(Product).filter(Product.name.ilike(f"%{query}%")).all()

        result = []
        for p in products:
            main_img = (
                db.query(ProductImages)
                .filter(
                    ProductImages.product_id == p.id, ProductImages.is_main == True
                )
                .first()
            )
            if not main_img:
                main_img = (
                    db.query(ProductImages)
                    .filter(ProductImages.product_id == p.id)
                    .first()
                )
            result.append(
                {
                    "id": p.id,
                    "name": p.name,
                    "brand": p.brand.name if p.brand else "",
                    "category_id": p.category_id,
                    "price": float(p.price),
                    "discount": float(p.discount),
                    "image_url": main_img.image_url if main_img else "",
                    "count_feedbacks": p.reviews_count,
                    "evaluation": float(p.rating),
                    "is_popular": p.is_popular,
                    "is_new": p.is_new,
                    "quantity": p.quantity,
                }
            )
        return result
```

**Описание:** Функция выполняет поиск товаров:

1. Ищет товары, название которых содержит строку запроса (без учета регистра)
2. Для каждого найденного товара получает основное изображение
3. Формирует список объектов с информацией о товарах (id, название, бренд, цена, скидка, рейтинг, количество отзывов и т.д.)
4. Возвращает отформатированный список результатов поиска

### Фильтрация товаров

```python
@product_router.get("/filter", summary="Фильтрация товаров")
def filter_products(
    sort: Optional[str] = None,
    popular: bool = False,
    high_rating: bool = False,
    big_discount: bool = False,
    is_new: bool = False,
    category_id: Optional[int] = None,
):
    from database.auth import filter_products as db_filter_products

    products = db_filter_products(
        sort_by=sort,
        popular=popular,
        high_rating=high_rating,
        big_discount=big_discount,
        is_new=is_new,
        category_id=category_id,
    )
    return products
```

**Описание:** Эндпоинт фильтрует товары по различным критериям: популярность, рейтинг, размер скидки, новизну и категорию. Поддерживает сортировку по цене, рейтингу и дате добавления.

#### Подфункция: filter_products

```python
def filter_products(
    sort_by=None,
    popular=False,
    high_rating=False,
    big_discount=False,
    is_new=False,
    category_id=None,
):
    """Фильтрация товаров с различными параметрами."""
    with Session(autoflush=False, bind=engine) as db:
        query = db.query(Product)

        # Фильтры
        if popular:
            query = query.filter(Product.is_popular == True)
        if high_rating:
            query = query.filter(Product.rating >= 4.0)
        if big_discount:
            query = query.filter(Product.discount >= 30.0)
        if is_new:
            query = query.filter(Product.is_new == True)
        if category_id:
            query = query.filter(Product.category_id == category_id)

        # Сортировка
        if sort_by == "price_asc":
            query = query.order_by(Product.price.asc())
        elif sort_by == "price_desc":
            query = query.order_by(Product.price.desc())
        elif sort_by == "rating":
            query = query.order_by(Product.rating.desc())
        elif sort_by == "newest":
            query = query.order_by(Product.created_at.desc())
        else:
            query = query.order_by(Product.id)

        products = query.all()

        result = []
        for p in products:
            main_img = (
                db.query(ProductImages)
                .filter(
                    ProductImages.product_id == p.id, ProductImages.is_main == True
                )
                .first()
            )
            if not main_img:
                main_img = (
                    db.query(ProductImages)
                    .filter(ProductImages.product_id == p.id)
                    .first()
                )
            result.append(
                {
                    "id": p.id,
                    "name": p.name,
                    "brand": p.brand.name if p.brand else "",
                    "category_id": p.category_id,
                    "price": float(p.price),
                    "discount": float(p.discount),
                    "image_url": main_img.image_url if main_img else "",
                    "count_feedbacks": p.reviews_count,
                    "evaluation": float(p.rating),
                    "quantity": p.quantity,
                    "is_new": p.is_new,
                    "is_popular": p.is_popular,
                }
            )
        return result
```

**Описание:** Функция выполняет фильтрацию и сортировку товаров:

1. Применяет фильтры по популярности (is_popular == True)
2. Применяет фильтр по рейтингу (rating >= 4.0)
3. Применяет фильтр по скидке (discount >= 30.0)
4. Применяет фильтр по новизне (is_new == True)
5. Применяет фильтр по категории
6. Выполняет сортировку: по цене (возрастание/убывание), по рейтингу (убывание) или по дате добавления (новые первыми)
7. Для каждого товара получает основное изображение
8. Формирует список с информацией о товарах
9. Возвращает отформатированный список результатов

---

## 3.2.4. Выполнение функции просмотра подробной информации о товаре

```python
@product_router.get(
    "/{product_id}/details", summary="Получить подробную информацию о товаре"
)
def read_product_details(product_id: int):
    product = get_detailed_product_by_id(product_id)
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found"
        )
    return product
```

**Описание:** Эндпоинт возвращает полную подробную информацию о товаре по его ID, включая все поля и информацию о бренде.

### Подфункция: get_detailed_product_by_id

```python
def get_detailed_product_by_id(product_id: int):
    """Получить подробную информацию о товаре включая все поля и информацию о производителе."""
    with Session(autoflush=False, bind=engine) as db:
        p = db.query(Product).filter(Product.id == product_id).first()
        if not p:
            return None
        main_img = (
            db.query(ProductImages)
            .filter(
                ProductImages.product_id == p.id, ProductImages.is_main == True
            )
            .first()
        )
        if not main_img:
            main_img = (
                db.query(ProductImages).filter(ProductImages.product_id == p.id).first()
            )

        # Собрать все изображения товара
        all_images = (
            db.query(ProductImages).filter(ProductImages.product_id == p.id).all()
        )
        images = [{"url": img.image_url, "is_main": img.is_main} for img in all_images]

        return {
            "id": p.id,
            "name": p.name,
            "category_id": p.category_id,
            "brand_id": p.brand_id,
            "price": float(p.price),
            "discount": float(p.discount),
            "image_url": main_img.image_url if main_img else "",
            "images": images,
            "count_feedbacks": p.reviews_count,
            "evaluation": float(p.rating),
            "description": p.description,
            "specifications": p.specifications,
            "warranty": p.warranty,
            "color": p.color,
            "dimensions": p.dimensions,
            "weight": p.weight,
            "is_new": p.is_new,
            "is_popular": p.is_popular,
            "quantity": p.quantity,
            "sold_count": p.sold_count,
            "brand": p.brand.name,
        }
```

**Описание:** Функция выполняет следующие операции:

1. Ищет товар в БД по product_id
2. Получает основное изображение товара (или первое изображение, если основного нет)
3. Собирает все изображения товара с информацией о том, является ли каждое основным
4. Формирует и возвращает полный объект с подробной информацией о товаре, включая:
   - Основную информацию (id, название, категория, бренд)
   - Цену и скидку
   - Изображение и список всех изображений
   - Рейтинг и количество отзывов
   - Описание и характеристики
   - Гарантию, цвет, размеры, вес
   - Статусы новизны и популярности
   - Количество на складе и количество проданных единиц
   - Информацию о бренде

---

## 3.2.5. Выполнение функции оформления заказа

```python
@orders_router.post("/checkout", summary="Create order from cart")
def checkout(data: CheckoutIn, user_email: str = Depends(get_current_user_email)):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    uid = getattr(user, "id", None)
    if uid is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="invalid user id"
        )

    lock = _checkout_locks.setdefault(uid, Lock())
    if not lock.acquire(blocking=False):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Another checkout in progress for this user",
        )

    try:
        # basic payment parsing
        now = datetime.now(timezone.utc)
        if data.payment_method == "card":
            digits = _card_digits_only(data.card_pan)
            if not _card_pan_length_ok(digits):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Некорректный номер карты (нужно 13–19 цифр)",
                )
            payment_status = "paid"
            paid_at = now
            payment_method = "card"
        else:
            payment_status = "pending"
            paid_at = None
            payment_method = "cash"

        # validate cart contents (no negative/zero quantities and product_ids filter)
        cart_items = get_cart_items_for_user(user)
        if data.product_ids:
            wanted = set(data.product_ids)
            cart_items = [c for c in cart_items if c.product_id in wanted]

        if not cart_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="cart is empty"
            )

        for c in cart_items:
            if getattr(c, "quantity", 0) <= 0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="invalid cart item quantity",
                )

        try:
            return create_order_from_cart(
                user=user,
                delivery_type_id=data.delivery_type_id,
                city_id=data.city_id,
                shipping_address=data.shipping_address,
                phone=data.phone,
                pickup_point_id=data.pickup_point_id,
                product_ids=data.product_ids,
                payment_method=payment_method,
                payment_status=payment_status,
                paid_at=paid_at,
            )
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
            ) from exc
    finally:
        try:
            lock.release()
        except RuntimeError:
            pass
```

**Описание:** Эндпоинт оформляет заказ на основе содержимого корзины авторизованного пользователя. Включает валидацию способа оплаты и использует блокировку для предотвращения конкурентных операций оформления заказа для одного пользователя.

### Подфункция: create_order_from_cart

```python
def create_order_from_cart(
    user: User,
    delivery_type_id: int,
    city_id: int | None,
    shipping_address: str,
    phone: str,
    pickup_point_id: int | None = None,
    product_ids: list[int] | None = None,
    *,
    payment_method: str,
    payment_status: str,
    paid_at: datetime | None,
) -> dict:
    with Session(autoflush=False, bind=engine) as db:
        delivery_type = (
            db.query(DeliveryType).filter(DeliveryType.id == delivery_type_id).first()
        )
        if not delivery_type:
            raise ValueError("delivery type not found")

        city = None
        pickup_point = None
        order_shipping_address = shipping_address
        order_city_id = None
        order_pickup_point_id = None

        if pickup_point_id is not None or ("Самовывоз" in (delivery_type.name or "")):
            # Самовывоз: нужен город и ПВЗ, адрес строим из текущих значений справочников.
            if city_id is None:
                raise ValueError("city_id is required for pickup")
            if pickup_point_id is None:
                raise ValueError("pickup_point_id is required for pickup")

            city = db.query(City).filter(City.id == city_id).first()
            if not city:
                raise ValueError("city not found")
            pickup_point = (
                db.query(PickupPoint).filter(PickupPoint.id == pickup_point_id).first()
            )
            if not pickup_point:
                raise ValueError("pickup point not found")

            order_city_id = city.id
            order_pickup_point_id = pickup_point.id
            if pickup_point.address:
                order_shipping_address = f"{city.name}, {pickup_point.address}"
            else:
                order_shipping_address = f"{city.name}, {pickup_point.name}"
        else:
            # Доставка: город/ПВЗ не привязываем.
            order_shipping_address = shipping_address
            order_city_id = None
            order_pickup_point_id = None

        cart_items_query = db.query(Cart).filter(Cart.user_id == user.id)
        if product_ids is not None and len(product_ids) > 0:
            cart_items_query = cart_items_query.filter(Cart.product_id.in_(product_ids))

        cart_items = cart_items_query.all()
        if not cart_items:
            raise ValueError("cart is empty")

        status = _get_or_create_status(db, OrderStatusEnum.pending)

        estimated_days = 3
        delivery_comment = None
        if pickup_point is not None:
            estimated_days = max(1, int(pickup_point.estimated_days or 1))
            delivery_comment = (
                f"Ориентировочная дата прибытия в пункт выдачи через {estimated_days} дн."
            )
        else:
            delivery_comment = "Ориентировочная дата курьерской доставки."

        order = Order(
            user_id=user.id,
            delivery_type_id=delivery_type.id,
            status_id=status.id,
            shipping_address=order_shipping_address,
            city_id=order_city_id,
            pickup_point_id=order_pickup_point_id,
            phone=phone,
            total_amount=0,
            estimated_delivery_at=None,
            delivery_comment=delivery_comment,
            payment_method=payment_method,
            payment_status=payment_status,
            paid_at=paid_at,
        )
        db.add(order)
        db.flush()  # get order.id
        if order.created_at is not None:
            order.estimated_delivery_at = order.created_at + timedelta(days=estimated_days)

        total = 0
        sorted_cart = sorted(cart_items, key=lambda r: r.product_id)
        for cart_row in sorted_cart:
            price_row = db.execute(
                select(Product.price).where(Product.id == cart_row.product_id)
            ).first()
            if not price_row:
                db.rollback()
                raise ValueError(f"product {cart_row.product_id} not found")

            price = price_row[0]
            res = db.execute(
                update(Product)
                .where(
                    Product.id == cart_row.product_id,
                    Product.quantity >= cart_row.quantity,
                )
                .values(quantity=Product.quantity - cart_row.quantity)
            )
            if res.rowcount != 1:
                db.rollback()
                raise ValueError(
                    f"insufficient stock for product {cart_row.product_id}"
                )

            line_total = float(price) * cart_row.quantity
            total += line_total

            db.add(
                OrderItem(
                    order_id=order.id,
                    product_id=cart_row.product_id,
                    quantity=cart_row.quantity,
                    price=price,
                )
            )

        order.total_amount = total

        for row in cart_items:
            db.delete(row)

        db.commit()
        db.refresh(order)
        return _order_checkout_payload(order)
```

**Описание:** Функция выполняет следующие операции по созданию заказа из корзины:

1. Проверяет наличие типа доставки
2. В зависимости от типа доставки:
   - Для самовывоза: проверяет наличие города и пункта выдачи, формирует адрес
   - Для доставки: использует переданный адрес
3. Получает товары из корзины пользователя (или отфильтрованный список)
4. Создаёт заказ со статусом "pending" и рассчитанной датой доставки
5. Для каждого товара в корзине:
   - Получает текущую цену товара
   - Уменьшает количество товара на складе на заказанное количество
   - Проверяет наличие достаточного количества товара
   - Создаёт элемент заказа (OrderItem)
   - Добавляет стоимость товара к общей сумме
6. Сохраняет общую сумму в заказ
7. Удаляет товары из корзины
8. Сохраняет всё в БД и возвращает информацию о заказе

---

## 3.2.6. Выполнение функции добавления товаров в избранное

```python
@favorites_router.post("/toggle", summary="Toggle favorite for product")
def toggle_favorite(
    data: FavoriteIn, user_email: str = Depends(get_current_user_email)
):
    user = get_user_by_email(user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    is_favorite = toggle_favorite_for_user(user, data.product_id)
    return {"is_favorite": is_favorite}
```

**Описание:** Эндпоинт переключает статус избранного для товара. Если товар был в избранном, он удаляется; если его не было, добавляется.

### Подфункция: toggle_favorite_for_user

```python
def toggle_favorite_for_user(user: User, product_id: int) -> bool:
    """
    Переключает избранное для товара.
    Возвращает True, если товар стал избранным, False — если был удалён.
    """
    with Session(autoflush=False, bind=engine) as db:
        favorite = (
            db.query(Favorites)
            .filter(
                Favorites.user_id == user.id,
                Favorites.product_id == product_id,
            )
            .first()
        )

        if favorite:
            db.delete(favorite)
            db.commit()
            return False

        new_favorite = Favorites(user_id=user.id, product_id=product_id)
        db.add(new_favorite)
        db.commit()
        return True
```

**Описание:** Функция выполняет переключение статуса избранного товара:

1. Ищет запись о избранном товаре для пользователя в БД
2. Если товар найден в избранном:
   - Удаляет его из избранного
   - Сохраняет изменения
   - Возвращает False
3. Если товара нет в избранном:
   - Создаёт новую запись в Favorites
   - Сохраняет её в БД
   - Возвращает True

---

## 3.2.7. Выполнение функции просмотра информации о заказе

```python
def get_order_detail_by_id(order_id: int) -> dict:
    with Session(autoflush=False, bind=engine) as db:
        order = db.query(Order).filter(Order.id == order_id).first()
        if not order:
            raise ValueError("order not found")

        items: list[dict] = []
        for it in order.items:
            items.append(
                {
                    "product_id": it.product_id,
                    "product_name": it.product.name if it.product else "",
                    "product_image_url": _get_product_main_image_url(db, it.product_id),
                    "quantity": it.quantity,
                    "price": float(it.price),
                    "line_total": float(it.price) * it.quantity,
                }
            )

        return {
            "id": order.id,
            "status": (
                order.status.name.value
                if order.status and isinstance(order.status.name, OrderStatusEnum)
                else (
                    str(order.status.name)
                    if order.status and order.status.name
                    else None
                )
            ),
            "delivery_type": order.delivery_type.name if order.delivery_type else None,
            "shipping_address": order.shipping_address,
            "phone": order.phone,
            "total_amount": float(order.total_amount),
            "created_at": order.created_at.isoformat() if order.created_at else None,
            "processed_at": order.processed_at.isoformat() if order.processed_at else None,
            "shipped_at": order.shipped_at.isoformat() if order.shipped_at else None,
            "ready_for_pickup_at": (
                order.ready_for_pickup_at.isoformat() if order.ready_for_pickup_at else None
            ),
            "delivered_at": order.delivered_at.isoformat() if order.delivered_at else None,
            "pickup_at": order.pickup_at.isoformat() if order.pickup_at else None,
            "estimated_delivery_at": (
                order.estimated_delivery_at.isoformat()
                if order.estimated_delivery_at
                else None
            ),
            "delivery_comment": order.delivery_comment,
            "canceled_at": (
                order.canceled_at.isoformat() if order.canceled_at else None
            ),
            "payment_status": order.payment_status,
            "payment_method": order.payment_method,
            "paid_at": order.paid_at.isoformat() if order.paid_at else None,
            "items": items,
        }
```

**Описание:** Функция выполняет следующие операции по получению подробной информации о заказе:

1. Ищет заказ в БД по order_id
2. Для каждого товара в заказе собирает информацию:
   - ID и название товара
   - Изображение товара
   - Количество и цену товара
   - Общую стоимость товара (цена × количество)
3. Формирует полный объект заказа, включая:
   - Основную информацию (id, статус, тип доставки)
   - Информацию доставки (адрес, телефон)
   - Сумму заказа
   - Даты всех этапов (создание, обработка, отправка, готовность к выдаче, доставка, самовывоз, отмена)
   - Комментарий доставки
   - Информацию об оплате (статус, метод, дата оплаты)
   - Список товаров в заказе

---

## 3.2.8. Выполнение функции работы с отзывами о товарах

```python
@product_router.post(
    "/{product_id}/reviews", summary="Оставить отзыв о товаре", status_code=201
)
def create_product_review(
    product_id: int,
    payload: dict,
    user: User = Depends(_get_current_user),
):
    try:
        return add_review_for_product(
            user=user,
            product_id=product_id,
            rating=payload.get("rating"),
            comment=payload.get("comment"),
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)
        ) from exc
```

**Описание:** Эндпоинт позволяет авторизованному пользователю оставить отзыв о товаре с рейтингом и опциональным комментарием.

### Подфункция: add_review_for_product

```python
def add_review_for_product(
    user: User,
    product_id: int,
    rating: float,
    comment: str | None = None,
) -> dict:
    """Создать отзыв от авторизованного пользователя; рейтинг обязателен, комментарий опционален."""
    if rating <= 0:
        raise ValueError("rating must be > 0")
    with Session(autoflush=False, bind=engine) as db:
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            raise ValueError("product not found")

        review = Reviews(
            user_id=user.id,
            product_id=product.id,
            rating=rating,
            comment=comment or "",
        )
        db.add(review)
        db.flush()

        # обновим агрегаты по продукту
        all_reviews = db.query(Reviews).filter(Reviews.product_id == product.id).all()
        if all_reviews:
            product.reviews_count = len(all_reviews)
            product.rating = sum(float(r.rating) for r in all_reviews) / len(
                all_reviews
            )

        db.commit()
        db.refresh(review)

        return {
            "id": review.id,
            "user_id": review.user_id,
            "product_id": review.product_id,
            "comment": review.comment,
            "rating": float(review.rating),
            "created_at": review.created_at.isoformat() if review.created_at else None,
            "user_name": user.name,
        }
```

**Описание:** Функция выполняет следующие операции по добавлению отзыва о товаре:

1. Проверяет валидность рейтинга (должен быть > 0)
2. Ищет товар в БД по product_id
3. Создаёт новый отзыв с информацией пользователя, товара, рейтинга и комментария
4. Сохраняет отзыв в БД
5. Обновляет агрегированные данные товара:
   - Пересчитывает количество отзывов
   - Пересчитывает средний рейтинг товара как среднее арифметическое всех рейтингов
6. Сохраняет обновленные данные товара в БД
7. Возвращает информацию об созданном отзыве, включая id, данные пользователя и товара, рейтинг, комментарий, дату создания и имя автора
