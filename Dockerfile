FROM ocaml/opam:debian-ocaml-4.14 AS builder

WORKDIR /marina

COPY ./marina/ ./

RUN opam install dune --yes
RUN opam install ocamlfind --yes

RUN eval $(opam env) && dune build main.exe

FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    python3-pip \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /marina/_build/default/main.exe /app/marina_exec
RUN chmod +x /app/marina_exec

COPY ./api/ /app/api

WORKDIR /app/api
RUN pip install --no-cache-dir -r requirements.txt

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]