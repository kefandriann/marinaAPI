FROM ocaml/opam:debian-ocaml-4.14 AS builder

WORKDIR /app/marina

COPY ./marina/ ./

RUN opam install dune ocamlfind --yes

RUN eval $(opam env) && dune build main.exe

FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    python3-dev \
    libffi-dev \
    libssl-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
RUN echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list
RUN apt-get update && apt-get install -y ngrok

ENV NGROK_AUTHTOKEN=${NGROK_AUTHTOKEN}

COPY --from=builder /app/marina/_build/default/main.exe /app/marina_exec
RUN chmod +x /app/marina_exec

COPY ./api/ /app/api

WORKDIR /app/api
RUN pip install --no-cache-dir -r requirements.txt

RUN apt-get update && apt-get install -y unzip curl
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
RUN echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list
RUN apt-get update && apt-get install ngrok -y

CMD ngrok http 8000 --authtoken "$NGROK_AUTHTOKEN" & \
    uvicorn api:app --host 0.0.0.0 --port 8000