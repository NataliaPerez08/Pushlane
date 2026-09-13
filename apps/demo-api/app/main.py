from fastapi import FastAPI

app = FastAPI(title="Pushlane Demo API", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": app.version}


@app.get("/api/hello")
def hello() -> dict[str, str]:
    return {"message": "Hello from Pushlane"}

