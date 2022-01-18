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

# D4 CNF to decision-DNNF
# usage: ./d4 -dDNNF benchTest/littleTest.cnf -out=/tmp/test.nnf -drat=/tmp/test.drat
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata

RUN wget https://www.cril.univ-artois.fr/KC/ressources/d4 && \
    chmod u+x d4

ENV PATH=$PATH:/tools/d4

RUN apt install unzip

RUN wget http://www.cril.univ-artois.fr/kc/ressources/query-dnnf-0.4.180625.zip && \
    unzip query-dnnf-0.4.180625.zip && \
    mv query-dnnf-0.4.180625 query-dnnf && \
    cd query-dnnf && \
    ./configure && \
    make

ENV PATH=$PATH:/tools/query-dnnf

# Install the minisat solver
RUN apt-get install minisat

# Install MARCO implementation
RUN git clone https://github.com/pauleon2/MARCO.git && \
    cd MARCO/pyminisolvers && \
    make

ENV PATH=$PATH:/tools/MARCO

# INSTALL Z3
WORKDIR /tools/z3
ENV Z3_VERSION "4.8.14"

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
    
RUN pip3 install z3-solver

# PySDD
# https://github.com/wannesm/PySDD/pull/20/files
WORKDIR /tools
RUN pip3 install cysignals numpy cython

# Install pysdd, the easy way
RUN pip3 install pysdd
    
# pySAT
RUN pip3 install python-sat[pblib,aiger]

# OR tools
# https://github.com/juanmarcosdev/docker-minizinc-google-or-tools/blob/master/Dockerfile
WORKDIR /tools
RUN wget https://github.com/google/or-tools/releases/download/v9.2/or-tools_amd64_flatzinc_ubuntu-20.04_v9.2.9972.tar.gz && \
    tar -xzvf or-tools_amd64_flatzinc_ubuntu-20.04_v9.2.9972.tar.gz

RUN cp -r or-tools_flatzinc_Ubuntu-20.04-64bit_v9.2.9972/bin /usr && \
    cp -r or-tools_flatzinc_Ubuntu-20.04-64bit_v9.2.9972/lib /usr && \
    mkdir -p /usr/local/share/minizinc/ortools && \
    mv or-tools_flatzinc_Ubuntu-20.04-64bit_v9.2.9972/share/minizinc/* /usr/local/share/minizinc/ortools/

RUN echo "{ \n\
  \"id\": \"com.google.or-tools\",\n\
  \"name\": \"OR-Tools\",\n\
  \"description\": \"OR Tools Constraint Programming Solver (from Google)\",\n\
  \"version\": \"9.2.9972\",\n\
  \"mznlib\": \"-Gortools\",\n\
  \"executable\": \"../../../bin/fzn-or-tools\",\n\
  \"tags\": [\"cp\",\"int\", ],\n\
  \"stdFlags\": [\"-a\",\"-n\",\"-s\",\"-v\",\"-p\",\"-f\",\"-t\"],\n\
  \"supportsMzn\": false,\n\
  \"supportsFzn\": true,\n\
  \"needsSolns2Out\": true,\n\
  \"needsMznExecutable\": false,\n\
  \"needsStdlibDir\": false,\n\
  \"isGUIApplication\": false \n\
}" >> /usr/local/share/minizinc/solvers/or-tools.msc

RUN rm or-tools_amd64_flatzinc_ubuntu-20.04_v9.2.9972.tar.gz && \
    rm -r or-tools_flatzinc_Ubuntu-20.04-64bit_v9.2.9972/

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
