FROM ocaml/opam:ubuntu-22.04-ocaml-5.4 AS builder

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends curl git libev-dev libssl-dev && \
    sudo apt-get remove -y nodejs npm && sudo apt-get autoremove -y

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends nodejs && \
    sudo npm install -g npm@latest

RUN sudo ln -sf /usr/bin/opam-2.5 /usr/bin/opam && opam init --reinit -n

WORKDIR /app

RUN opam remote set-url default https://opam.ocaml.org
RUN cd ~/opam-repository && git fetch -q origin master && git reset --hard origin/master && opam update -y

COPY Makefile ./
COPY *.opam ./
COPY *.opam.template ./
COPY dune ./
COPY dune-project ./

RUN make pin
RUN opam update -y && opam install . --deps-only -y && opam install dream -y

WORKDIR /app/demo
COPY demo/package.json ./package.json
COPY demo/package-lock.json ./package-lock.json
RUN sudo npm ci --omit=dev

WORKDIR /app/demo/client
COPY demo/client/package.json ./package.json
COPY demo/client/package-lock.json ./package-lock.json
RUN sudo npm install

WORKDIR /app
COPY . .
RUN sudo chown -R opam:opam /app && opam exec -- dune build @demo --profile=dev
RUN opam clean -a -c -s --logs && rm -rf /home/opam/opam-repository

FROM ocaml/opam:ubuntu-22.04-ocaml-5.4

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends libev4 libssl3 && \
    sudo rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder --chown=opam:opam /home/opam/.opam /home/opam/.opam
COPY --from=builder --chown=opam:opam /app /app

ENV PATH="/home/opam/.opam/5.4/bin:${PATH}"

EXPOSE 8080

CMD ["opam", "exec", "--switch", "5.4", "--", "_build/default/demo/server/server.exe"]
