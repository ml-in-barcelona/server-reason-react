FROM ocaml/opam:ubuntu-22.04-ocaml-5.1

RUN sudo apt-get update && sudo apt-get install -y libev-dev libssl-dev curl

RUN sudo apt-get remove -y nodejs npm && \
    sudo apt-get autoremove -y

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    sudo apt-get update && \
    sudo apt-get install -y nodejs && \
    sudo npm install -g npm@latest

RUN sudo ln -sf /usr/bin/opam-2.2 /usr/bin/opam

WORKDIR /app

RUN opam --version

COPY *.opam ./
COPY Makefile ./

RUN opam install . --deps-only --with-test --with-doc --with-dev-setup

WORKDIR "/app/demo/client"

COPY demo/client/package.json ./package.json
COPY demo/client/package-lock.json ./package-lock.json

RUN sudo npm install

WORKDIR /app

COPY . .

RUN sudo chown -R opam:opam /app
RUN opam exec -- dune build @demo --profile=dev

EXPOSE 8080

CMD ["opam", "exec", "--", "_build/default/demo/server/server.exe"]
