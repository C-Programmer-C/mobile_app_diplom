using ManagementSystem.DetailViews;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace ManagementSystem
{
    public partial class ProductsForm: Form
    {
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();
        private readonly List<Dictionary<string, object>> _products = new List<Dictionary<string, object>>();
        private TextBox _textBoxSearch;
        private ComboBox _comboFilter;
        private Button _buttonApply;

        public ProductsForm()
        {
            InitializeComponent();
            InitToolbar();
            button1.Click += buttonCreate_Click;
        }

		private async void ProductsForm_Load(object sender, EventArgs e)
		{
            await LoadProductsAsync();
		}

		private void ProductsForm_FormClosing(object sender, FormClosingEventArgs e)
		{
			this.Close();
		}

        private void buttonBack_Click(object sender, EventArgs e)
        {
            this.Hide();
            MenuForm menu = new MenuForm();
            menu.Show();
        }

        private async Task LoadProductsAsync()
        {
            _products.Clear();
            flowLayoutProducts.Controls.Clear();
            flowLayoutProducts.FlowDirection = FlowDirection.TopDown;

            using (var client = new HttpClient())
            {
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/products/public");
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка загрузки товаров ({(int)response.StatusCode})");
                    return;
                }

                var json = await response.Content.ReadAsStringAsync();
                var items = _serializer.DeserializeObject(json) as object[];
                if (items == null || items.Length == 0)
                {
                    flowLayoutProducts.Controls.Add(new Label { Text = "Товары не найдены", AutoSize = true });
                    return;
                }

                foreach (var item in items)
                {
                    var product = item as Dictionary<string, object>;
                    if (product == null)
                    {
                        continue;
                    }
                    _products.Add(product);
                }
            }

            await RenderProductsAsync();
        }

        private async Task<Panel> BuildProductCardAsync(Dictionary<string, object> product)
        {
            var card = new Panel
            {
                Width = 730,
                Height = 130,
                BackColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle,
                Margin = new Padding(4),
                Tag = product.ContainsKey("id") ? Convert.ToInt32(product["id"]) : 0,
            };

            var picture = new PictureBox
            {
                Left = 8,
                Top = 8,
                Width = 110,
                Height = 110,
                SizeMode = PictureBoxSizeMode.Zoom,
                BorderStyle = BorderStyle.FixedSingle
            };

            var name = Convert.ToString(product.ContainsKey("name") ? product["name"] : "") ?? "-";
            var id = Convert.ToString(product.ContainsKey("id") ? product["id"] : "") ?? "-";
            var brand = Convert.ToString(product.ContainsKey("brand") ? product["brand"] : "") ?? "-";
            var categoryId = Convert.ToString(product.ContainsKey("category_id") ? product["category_id"] : "") ?? "-";
            var price = Convert.ToString(product.ContainsKey("price") ? product["price"] : "") ?? "-";
            var quantity = Convert.ToString(product.ContainsKey("quantity") ? product["quantity"] : "") ?? "-";
            var rating = Convert.ToString(product.ContainsKey("rating") ? product["rating"] : "") ?? "-";
            var evaluation = Convert.ToString(product.ContainsKey("evaluation") ? product["evaluation"] : "") ?? "-";
            var feedbacks = Convert.ToString(product.ContainsKey("count_feedbacks") ? product["count_feedbacks"] : "") ?? "-";
            var discount = Convert.ToString(product.ContainsKey("discount") ? product["discount"] : "") ?? "-";
            var imageUrl = Convert.ToString(product.ContainsKey("image_url") ? product["image_url"] : "") ?? "";
            var isNew = ToBool(product, "is_new") ? "Да" : "Нет";
            var isPopular = ToBool(product, "is_popular") ? "Да" : "Нет";

            card.Click += Card_Click;

            var labelTitle = new Label
            {
                Left = 130,
                Top = 10,
                Width = card.Width - 145,
                Height = 24,
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                Text = $"{name} (ID: {id})"
            };

            var labelInfo = new Label
            {
                Left = 130,
                Top = 36,
                Width = card.Width - 145,
                Height = 20,
                Font = new Font("Segoe UI", 9, FontStyle.Regular),
                Text = $"Бренд: {brand} | Категория ID: {categoryId} | Скидка: {discount}%"
            };

            var labelMetrics = new Label
            {
                Left = 130,
                Top = 56,
                Width = card.Width - 145,
                Height = 20,
                Font = new Font("Segoe UI", 9, FontStyle.Regular),
                Text = $"Цена: {price} | Остаток: {quantity} | Рейтинг: {rating} | Оценка: {evaluation}"
            };

            var labelFlags = new Label
            {
                Left = 130,
                Top = 78,
                Width = card.Width - 145,
                Height = 20,
                Font = new Font("Segoe UI", 9, FontStyle.Regular),
                Text = $"Отзывов: {feedbacks} | Новинка: {isNew} | Популярный: {isPopular}"
            };

            card.Controls.Add(picture);
            card.Controls.Add(labelTitle);
            card.Controls.Add(labelInfo);
            card.Controls.Add(labelMetrics);
            card.Controls.Add(labelFlags);
            labelTitle.Click += Card_Click;
            labelInfo.Click += Card_Click;
            labelMetrics.Click += Card_Click;
            labelFlags.Click += Card_Click;
            picture.Click += Card_Click;

            if (!string.IsNullOrWhiteSpace(imageUrl))
            {
                try
                {
                    using (var imageClient = new HttpClient())
                    {
                        var imageBytes = await imageClient.GetByteArrayAsync(imageUrl);
                        using (var ms = new MemoryStream(imageBytes))
                        {
                            picture.Image = Image.FromStream(ms);
                        }
                    }
                }
                catch
                {
                    picture.BackColor = Color.Gainsboro;
                }
            }

            return card;
        }

		private void Card_Click(object sender, EventArgs e)
		{
            Control control = sender as Control;
            while (control != null && !(control is Panel && control.Tag is int))
            {
                control = control.Parent;
            }
            if (control == null) return;

            var panel = (Panel)control;
            var productId = (int)panel.Tag;
            var form = new ProductForm
            {
                ProductId = productId,
            };
            this.Hide();
            form.Show();
		}

        private void buttonCreate_Click(object sender, EventArgs e)
        {
            if (UserSession.UserRole != "admin" && UserSession.UserRole != "staff")
            {
                MessageBox.Show("Создание товара доступно только администратору или сотруднику");
                return;
            }
            var form = new ProductForm
            {
                IsCreateMode = true,
            };
            Hide();
            form.Show();
        }

		private void InitToolbar()
        {
            _textBoxSearch = new TextBox
            {
                Left = 120,
                Top = 63,
                Width = 220
            };
            _comboFilter = new ComboBox
            {
                Left = 350,
                Top = 63,
                Width = 220,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            _comboFilter.Items.AddRange(
                new object[]
                {
                    "Без фильтра",
                    "Популярные",
                    "Новинки",
                    "Высокий рейтинг (>=4)",
                    "Большая скидка (>=20%)",
                    "Есть скидка (>0%)",
                    "В наличии",
                    "Нет в наличии",
                    "Мало на складе (<=5)",
                    "Есть отзывы",
                    "Без отзывов",
                    "Цена: по возрастанию",
                    "Цена: по убыванию",
                    "Рейтинг: по убыванию",
                    "Остаток: по убыванию",
                }
            );
            _comboFilter.SelectedIndex = 0;
            _buttonApply = new Button
            {
                Left = 580,
                Top = 63,
                Width = 100,
                Height = 27,
                Text = "Применить"
            };
            _buttonApply.Click += async (s, e) => await RenderProductsAsync();
            Controls.Add(_textBoxSearch);
            Controls.Add(_comboFilter);
            Controls.Add(_buttonApply);
        }

        private async Task RenderProductsAsync()
        {
            flowLayoutProducts.Controls.Clear();
            var search = (_textBoxSearch.Text ?? string.Empty).Trim().ToLowerInvariant();
            var filter = Convert.ToString(_comboFilter.SelectedItem) ?? "Без фильтра";
            var filtered = _products.Where(p =>
            {
                var name = Convert.ToString(p.ContainsKey("name") ? p["name"] : "") ?? "";
                var brand = Convert.ToString(p.ContainsKey("brand") ? p["brand"] : "") ?? "";
                if (!string.IsNullOrWhiteSpace(search) &&
                    !name.ToLowerInvariant().Contains(search) &&
                    !brand.ToLowerInvariant().Contains(search))
                {
                    return false;
                }

                decimal rating = 0;
                decimal discount = 0;
                bool isPopular = ToBool(p, "is_popular");
                bool isNew = ToBool(p, "is_new");
                int quantity = 0;
                int feedbacks = 0;
                decimal.TryParse(Convert.ToString(p.ContainsKey("rating") ? p["rating"] : "0"), out rating);
                decimal.TryParse(Convert.ToString(p.ContainsKey("discount") ? p["discount"] : "0"), out discount);
                int.TryParse(Convert.ToString(p.ContainsKey("quantity") ? p["quantity"] : "0"), out quantity);
                int.TryParse(Convert.ToString(p.ContainsKey("count_feedbacks") ? p["count_feedbacks"] : "0"), out feedbacks);

                if (filter == "Популярные") return isPopular;
                if (filter == "Новинки") return isNew;
                if (filter == "Высокий рейтинг (>=4)") return rating >= 4;
                if (filter == "Большая скидка (>=20%)") return discount >= 20;
                if (filter == "Есть скидка (>0%)") return discount > 0;
                if (filter == "В наличии") return quantity > 0;
                if (filter == "Нет в наличии") return quantity <= 0;
                if (filter == "Мало на складе (<=5)") return quantity > 0 && quantity <= 5;
                if (filter == "Есть отзывы") return feedbacks > 0;
                if (filter == "Без отзывов") return feedbacks == 0;
                return true;
            }).ToList();

            if (filter == "Цена: по возрастанию")
            {
                filtered = filtered.OrderBy(p => ToDecimal(p, "price")).ToList();
            }
            else if (filter == "Цена: по убыванию")
            {
                filtered = filtered.OrderByDescending(p => ToDecimal(p, "price")).ToList();
            }
            else if (filter == "Рейтинг: по убыванию")
            {
                filtered = filtered.OrderByDescending(p => ToDecimal(p, "rating")).ToList();
            }
            else if (filter == "Остаток: по убыванию")
            {
                filtered = filtered.OrderByDescending(p => ToDecimal(p, "quantity")).ToList();
            }

            if (filtered.Count == 0)
            {
                flowLayoutProducts.Controls.Add(new Label { Text = "Ничего не найдено", AutoSize = true });
                return;
            }

            foreach (var product in filtered)
            {
                var card = await BuildProductCardAsync(product);
                flowLayoutProducts.Controls.Add(card);
            }
        }

        private static bool ToBool(Dictionary<string, object> source, string key)
        {
            if (!source.ContainsKey(key) || source[key] == null) return false;
            var value = Convert.ToString(source[key]) ?? string.Empty;
            return value.Equals("true", StringComparison.OrdinalIgnoreCase) || value == "1";
        }

        private static decimal ToDecimal(Dictionary<string, object> source, string key)
        {
            if (!source.ContainsKey(key) || source[key] == null) return 0;
            decimal.TryParse(Convert.ToString(source[key]), out var value);
            return value;
        }
	}
}
