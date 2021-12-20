FROM minizinc/minizinc:latest

RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get install -y git binutils make g++ wget

RUN pip3 install minizinc

# FZN2SMT (ALSO REQUIRES OPTIMSAT INSTALLATION)
WORKDIR /tools
RUN git clone https://github.com/PatrickTrentin88/fzn2omt.git

RUN wget http://optimathsat.disi.unitn.it/releases/optimathsat-1.7.2/optimathsat-1.7.2-linux-64-bit.tar.gz && \
    tar -xf optimathsat-1.7.2-linux-64-bit.tar.gz && \
    rm -f optimathsat-1.7.2-linux-64-bit.tar.gz

ENV PATH=$PATH:/tools/fzn2omt/bin:/tools/optimathsat-1.7.2-linux-64-bit/bin

# PySDD
# TODO: test
# https://github.com/wannesm/PySDD/pull/20/files
WORKDIR /tools

RUN git clone https://github.com/wannesm/PySDD.git
RUN pip3 install cysignals numpy cython

RUN cd PySDD && \
    make build && \
    python3 setup.py install

# D4 CNF to decision-DNNF
# usage: ./d4 -dDNNF benchTest/littleTest.cnf -out=/tmp/test.nnf -drat=/tmp/test.drat
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata

RUN git clone https://github.com/pauleon2/d4.git && \
    apt-get install -y libboost-all-dev libgmp-dev && \
    cd d4 && \
    make -j8

ENV PATH=$PATH:/tools/d4

# Install the minisat solver
RUN apt-get install minisat

# Install MARCO implementation
RUN git clone https://github.com/pauleon2/MARCO.git && \
    cd MARCO/pyminisolvers && \
    make

ENV PATH=$PATH:/tools/MARCO

# INSTALL Z3
WORKDIR /tools/z3
ENV Z3_VERSION "4.8.13"

RUN Z3_DIR="$(mktemp -d)" && \
    cd "$Z3_DIR" && \
    wget https://github.com/Z3Prover/z3/archive/z3-${Z3_VERSION}.tar.gz && \
    tar -xf z3-${Z3_VERSION}.tar.gz --strip-components=1 && \
    python3 scripts/mk_make.py --python && \
    cd build && \
    make && \
    make install && \
    cd .. && \
    rm -rf "$Z3_DIR"

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

CMD [ "/bin/bash" ]
