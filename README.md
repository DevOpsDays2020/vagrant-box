## Download CentOS 7 repo file
```

wget -O yum/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

```

## Customize Centos7 Box

```
make build

```

##  Clean Data

```
make clean

```

## Test Customized Box

```
cd test

vagrant up

vagrant ssh

vagrant halt && vagrant destroy -f
```