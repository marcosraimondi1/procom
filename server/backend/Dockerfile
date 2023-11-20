# imagen base de python
FROM python:3.8

# definimos la carpeta de trabajo
WORKDIR /backend

# update packages
RUN apt-get update \
    && apt-get install -y

# copiamos archivos exceptos los del .dockerignore
COPY . .

# install modules
RUN pip install -r requirements.txt

# definimos puertos
EXPOSE 8080

# corremos la aplicacion
CMD ["python3", "server.py"]
