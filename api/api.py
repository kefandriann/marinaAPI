from fastapi import FastAPI, Request
import subprocess

app = FastAPI()

@app.post("/marina")
async def solve(request: Request):
    data = await request.body()
    expr = data.decode("utf-8")

    try:
        result = subprocess.check_output(["/app/marina_exec", expr])
        return {"result": result.decode("utf-8").strip()}
    except subprocess.CalledProcessError as e:
        return {"error": e.output.decode("utf-8")}