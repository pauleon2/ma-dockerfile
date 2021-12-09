# Dockerfile for running experiments that require the MiniZinc interface
FROM minizinc/minizinc:latest-alpine

# INSTALL TOOLS
RUN apk add --no-cache --upgrade bash && \
    apk add --no-cache python3 py3-pip && \
    pip3 install minizinc

# INSTALL Z3
WORKDIR /tools/z3
ENV Z3_VERSION "4.8.13"
RUN apk --update add git binutils make g++ \
    && apk upgrade \
    && Z3_DIR="$(mktemp -d)" \
    && cd "$Z3_DIR" \
    && wget https://github.com/Z3Prover/z3/archive/z3-${Z3_VERSION}.tar.gz \
    && tar -xf z3-${Z3_VERSION}.tar.gz --strip-components=1 \
    && python3 scripts/mk_make.py --python \
    && cd build \
    && make \
    && make install \
    && cd .. \
    && rm -rf "$Z3_DIR"

# FZN2SMT (ALSO REQUIRES OPTIMSAT INSTALLATION)
WORKDIR /tools
RUN git clone https://github.com/PatrickTrentin88/fzn2omt.git

RUN wget http://optimathsat.disi.unitn.it/releases/optimathsat-1.7.2/optimathsat-1.7.2-linux-64-bit.tar.gz && \
    tar -xf optimathsat-1.7.2-linux-64-bit.tar.gz && \
    rm -f optimathsat-1.7.2-linux-64-bit.tar.gz

ENV PATH=$PATH:/tools/fzn2omt/bin:/tools/optimathsat-1.7.2-linux-64-bit/bin

# D4 CNF to decision-DNNF
# usage: ./d4 -dDNNF benchTest/littleTest.cnf -out=/tmp/test.nnf -drat=/tmp/test.drat
RUN apk add --no-cache --upgrade zlib-dev gmp-dev boost-dev && \
    git clone https://github.com/pauleon2/d4.git && \
    cd d4 && \
    make -j8

ENV PATH=$PATH:/tools/d4

# Install additional pieces of software
RUN pip3 install --upgrade pip && \
    apk add libffi-dev python3-dev && \
    pip3 install jupyter

# Install the minisat solver
RUN apk add zlib-dev && \
    git clone https://github.com/pauleon2/minisat.git && \
    cd minisat && \
    make install

# Install MARCO implementation
RUN git clone https://github.com/pauleon2/MARCO.git && \
    cd MARCO/pyminisolvers && \
    make

ENV PATH=$PATH:/tools/MARCO

# MAKE FOLDERS
WORKDIR /

# Folder for solutions obtained from the models
RUN mkdir /output
RUN mkdir /output/solutions

# Folder for automatically created models
RUN mkdir /output/mzn2z3
RUN mkdir /output/cnf
RUN mkdir /output/smt

# Folder for automatic testcases and results
RUN mkdir /output/data
RUN mkdir /output/results

# Expose the output ports
EXPOSE 8080
EXPOSE 8888
