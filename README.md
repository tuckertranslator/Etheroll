# Etheroll statistical analysis

See medium article:
[Statistical analysis of Etheroll's random number generation](https://medium.com/@tucker.translator/statistical-analysis-of-etherolls-random-number-generation-ed06fdbdd2a4)

This set of scripts is using the [Julia Programming Language](https://julialang.org/).

## Install
Install Julia lang (Ubuntu 18.04):
```sh
sudo snap install julia --classic
```
Insall package dependencies:
```sh
echo 'using Pkg; Pkg.add(["HTTP", "JSON"])' | julia
```
Run the scripts:
```sh
julia call_EtherscanAPI.jl
```
