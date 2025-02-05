FROM ocaml/opam:ubuntu-22.04-ocaml-5.1

RUN sudo apt-get update && sudo apt-get install -y libev-dev libssl-dev curl

RUN sudo apt-get remove -y nodejs npm && sudo apt-get autoremove -y

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    sudo apt-get update && \
    sudo apt-get install -y nodejs && \
    sudo npm install -g npm@latest

RUN sudo ln -sf /usr/bin/opam-2.3 /usr/bin/opam && opam init --reinit -n

WORKDIR /app

RUN opam --version

COPY *.opam ./
COPY *.opam.template ./

RUN cd ~/opam-repository && git pull origin master && git reset --hard 278df338effcd8a80241fbf6902ef949a850372c && opam update -y

RUN opam list
RUN opam repository list --all
RUN opam repo
RUN opam config list
RUN opam switch show
RUN opam install . --deps-only --with-test --with-doc --with-dev-setup -y
RUN opam list
RUN opam repository list --all
RUN opam repo
RUN opam config list
RUN opam switch show

WORKDIR "/app/demo/client"

COPY demo/client/package.json ./package.json
COPY demo/client/package-lock.json ./package-lock.json

RUN sudo npm install

WORKDIR /app

COPY . .

RUN ls
RUN sudo chown -R opam:opam /app

RUN opam exec -- dune build @demo --profile=dev

EXPOSE 8080

CMD ["opam", "exec", "--", "_build/default/demo/server/server.exe"]
