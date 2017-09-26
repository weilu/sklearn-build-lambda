#!/bin/bash
set -ex

yum update -y
yum install -y \
    atlas-devel \
    atlas-sse3-devel \
    blas-devel \
    gcc \
    gcc-c++ \
    lapack-devel \
    findutils \
    zip \
    zlib-devel \
    git \
    openssl \
    openssl-devel

do_pip () {
    pip3.6 install --upgrade pip wheel
    pip3.6 install --use-wheel --no-binary numpy numpy
    pip3.6 install --use-wheel --no-binary scipy scipy
    pip3.6 install --use-wheel sklearn
}

strip_virtualenv () {
    echo "venv original size $(du -sh $VIRTUAL_ENV | cut -f1)"
    find $VIRTUAL_ENV/lib64/python3.6/site-packages/ -name "*.so" | xargs strip
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    pushd $VIRTUAL_ENV/lib64/python3.6/site-packages/ && zip -r -9 -q /outputs/venv.zip * ; popd
    echo "site-packages compressed size $(du -sh /outputs/venv.zip | cut -f1)"

    pushd $VIRTUAL_ENV && zip -r -q /outputs/full-venv.zip * ; popd
    echo "venv compressed size $(du -sh /outputs/full-venv.zip | cut -f1)"
}

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python3.6/site-packages/lib/"
    mkdir -p $VIRTUAL_ENV/lib64/python3.6/site-packages/lib || true
    cp /usr/lib64/atlas/* $libdir
    cp /usr/lib64/libquadmath.so.0 $libdir
    cp /usr/lib64/libgfortran.so.3 $libdir
}

main () {

    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc
    exec "$SHELL"

    pyenv install 3.6.2
    pyenv global 3.6.2

    /usr/bin/virtualenv \
        --python /root/.pyenv/versions/3.6.2/bin/python /sklearn_build \
        --always-copy \
        --no-site-packages
    source /sklearn_build/bin/activate

    do_pip

    shared_libs

    strip_virtualenv

    

}
main
