from fastapi import FastAPI
import uvicorn
from api.auth import auth_router
from fastapi.staticfiles import StaticFiles
from api.product import product_router
from api.favorites import favorites_router
from api.cart import cart_router
from api.orders import orders_router

app = FastAPI()
app.include_router(auth_router, prefix="/auth")
app.include_router(product_router)
app.include_router(favorites_router)
app.include_router(cart_router)
app.include_router(orders_router)
app.mount("/static", StaticFiles(directory="static"), name="static")
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
