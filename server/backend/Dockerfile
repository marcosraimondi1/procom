# imagen base de python
FROM python:3.10.12

WORKDIR /backend

# update packages
RUN apt-get update \
    && apt-get install -y

# install libgl1 needed for opencv-python
RUN apt-get install libgl1-mesa-glx -y

# copiamos archivos exceptos los del .dockerignore
COPY . .

# install modules
RUN pip install -r requirements.txt

# definimos puertos
EXPOSE 8080

# corremos la aplicacion
CMD ["python3", "server.py"]
