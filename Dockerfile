FROM centos:7

USER root

RUN yum install -y httpd \
	zip \
	unzip 

ADD https://www.free-css.com/assets/files/free-css-templates/download/page276/ocean-vibes.zip /var/www/html/

WORKDIR /var/www/html/

RUN unzip ocean-vibes.zip

RUN cp -r ./*vibes/* ./

RUN sed -i 's/>vibes</>Breeze</g' index.html

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

EXPOSE 80
