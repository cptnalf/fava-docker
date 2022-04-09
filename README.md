# fava-docker
A Dockerfile for beancount-fava

## Environment Variable

- `BEANCOUNT_FILE`: path to your beancount file. Default to empty string.

## volumes

- <any>: where your beancount file is at.
- /bean-import: directory where 'import.py' lives which runs bean-import.

## Usage Example

```
# assume you have example.bean in the current directory
docker run \
  -v $PWD:/bean \
  -v ${PWD}/../bean-import:/bean-import \
  -e BEANCOUNT_FILE=/bean/example.bean \
  -e UID=$(id -u) -e GID=$(id -g) -e GIDLIST=i$(id -g) \
 cptnalf/fava:1.21
```

