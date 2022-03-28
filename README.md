# Table of contents

- General Info
- Technologies
- Setup


## General Info

The aim of this project is to create a CI/CD pipeline using Jenkins to implement a website deployment on Kubernetes.

First thing is to write a Docker file where we can run Apache (httpd) webserver with sample free template from ([https://templatemo.com/tm-554-ocean-vibes](https://templatemo.com/tm-554-ocean-vibes)) and copy to html directory and expose port 80. Similarly, write Kubernetes deployment & service yml file and Ansible-playbook files. Pull these file from [Kubernetes sources file repo](https://github.com/nav-InverseInfinity/kubernetes-source-files) to Jenkins workspace and copy onto Ansible server, then build the Docker image from there and upload to DockerHub. Following that, using Ansible playbook, copy the Kubernetes deployment file and deploy it on Kubernetes cluster, this will initiate the pods creation in Kubernetes. In order to see the IP and port of the running deployment and service on, execute another Ansible playbook which will execute a bash script on Kubernetes and display the ip and port of the running deployment, so we can see it from web browser.

   ![Kubernetes_project_flow](https://user-images.githubusercontent.com/98486154/160493937-1c2f1e4c-28fd-4a3f-b9ab-bef063217602.jpg)


## Technologies

- Bash Scripting
- Github
- Jenkins
- Docker
- Ansible
- Kubernetes
 


## Setup

As per the aim of this project, we need 3 VM instances, here we are using AWS EC2 instances, Install Ansible on ansible server for deployment and install minikube to run Kubernetes cluster in order run the Kubernetes deployment.

### Ansible installation for amazon-linux-2
```bash

#Update packages

sudo yum update -y

#Install ansible

sudo amazon-linux-extras install ansible2 -y

#Check version

ansible –version

```



On top ansible, we also need Docker to build docker image, for installation guide follow my docker-setup [repo]([https://github.com/nav-InverseInfinity/docker-setup](https://github.com/nav-InverseInfinity/docker-setup))

On the second VM instance, install Kubernetes to setup Kubernetes, please refer my Kubernetes installation guide on [here](https://github.com/nav-InverseInfinity/kubernetes-setup)

Similarly, on the third instance, install Jenkins for Continuous Integration and Continuous Deployment. To setup Jenkins please refer my Jenkins installation guide on [here](https://github.com/nav-InverseInfinity/Jenkins-setup)


### Project Source file - [refer here](https://github.com/nav-InverseInfinity/kubernetes-source-files)

Now that we have all the resources, we can start writing the codes for the project.

* Dockerfile

* Kubernetes Deployment & Service file in yml format 

* Ansible playbook to copy the file and deploy on Kubernetes Cluster 

* Ansible playbook to run a shell script on Kubernetes server to display the ip & port where our website deployment is running so we can view it on browser 



In order to automate the whole CI/CD environment, we will have to establish the connections between servers and do some ground work. Since we are going to connect to our ansible server, we will have to install “**SSH-Agent**” plugin and make the connection, please refer my guide to Jenkins connections [repo]([https://github.com/nav-InverseInfinity/Jenkins-setup](https://github.com/nav-InverseInfinity/Jenkins-setup)).


We should also establish connection between Ansible server and Kubernetes server via ssh

```bash

ssh-keygen  
#goto “./.ssh” and copy public id

cat ./.ssh/id_rsa.pub

#Then onto Kubernetes server under ./.ssh directory

vi authorized_keys

#paste the ansible server’s public id and save it

```

## Process - CI/CD Pipeline

Plan is to build Jenkins CI/CD pipeline, with environmental variables so we can pass in our credentials as a secret -  docker login password and AWS IP as “**secret text**”. DockerHub password = **PASS** and AWS IP = **AWS_IP**

### CI/CD Stages refer [here](https://github.com/nav-InverseInfinity/kubernetes-deployment/blob/main/Jenkins_Pipeline)


- #### *Grab Dockerfile* - pull the Docker file from Github repo	
```sh
git branch: 'main', url: 'https://github.com/nav-InverseInfinity/docker-webservice.git'
```


- #### *Push-Dockerfile to Ansible server* - copy the files from Jenkins’ workspace to Ansible server. 

```sh
scp /var/lib/jenkins/workspace/kubernetes_deployment/Docker* ec2-user@$AWS_IP:~/ansible/
```


- #### *Docker Build & Tag* - From Ansible server, build Docker image from docker file and tag the image based on the my DockerHub’s username and Jenkins’ Job_Name – example (inverseinfinity/kubernetes_deployment) 

```sh
ssh ec2-user@$AWS_IP "cd ~/ansible/ && docker build . -t $JOB_NAME:v1.$BUILD_ID" 
ssh ec2-user@$AWS_IP "cd ~/ansible/ && docker tag $JOB_NAME:v1.$BUILD_ID inverseinfinity/$JOB_NAME:latest"
```


- #### *Docker login & push to Docker Hub, once done delete the images* - Then tag the image, login to DockerHub and push it to my DockerHub’s repo. Once after that, delete the images, as we have already uploaded to DockerHub. 

```sh
ssh ec2-user@$AWS_IP "cd ~/ansible/ && docker login -u inverseinfinity -p $PASS" 
ssh ec2-user@$AWS_IP "cd ~/ansible/ && docker push inverseinfinity/$JOB_NAME:latest"
ssh ec2-user@$AWS_IP "cd ~/ansible/ && docker image rm inverseinfinity/$JOB_NAME:latest $JOB_NAME:v1.$BUILD_ID "
```
- #### *Copy deployment and playbook yaml files to ansible server* - Copying Kubernetes deployment & service yml file and Ansible playbook file from Jenkins’ workspace to Ansible server

```sh
scp /var/lib/jenkins/workspace/kubernetes_deployment/*.yml ec2-user@$AWS_IP:~/ansible/
```


- #### *Running Kubernetes Deployment using Ansible Playbook* - After copying the files, we will have to deploy it on Kubernetes cluster using “ansible playbook” 

```sh
ssh ec2-user@$AWS_IP "cd ~/ansible/ && ansible webserver"
ssh ec2-user@$AWS_IP "cd ~/ansible/ && ansible-playbook kubernetes-playbook.yml"
```

### This will successfully deploy and start the kuubernetes pods, thus the website will be up & running, however to see the ip and port of the running container n Kubernetes cluster we will have to run a bash script on Kubernetes server to find the ip and port.


- #### *Post success* - Copy the bashscript to Ansible server, with help of ansible playbook execute the script on Kubernetes server which will display the output of ip and port

```sh
scp /var/lib/jenkins/workspace/kubernetes_deployment/kube-ip-port.sh ec2-user@$AWS_IP:~/ansible/
ssh ec2-user@$AWS_IP "cd ~/ansible/ && chmod +x kube-ip-port.sh && ansible-playbook kube_ip_port-playbook.yml"
```

#### Since we need to automate the process, that is whenever there is a change in the source code, Jenkins should trigger and run the pipeline, so we can see the change on the deployment. 
#### To do this, would have to activate Github Webhook, and make changes in the code, I have made changes Dockerfile by replacing the html code of index.html from Ocean "vibes" to Ocean “Breeze”, this has successfully triggered the CI/CD pipeline and we could see the differences.

# Screenshots

### Display IP & Port of the running kubernetes deployment



![InkedKubernetes_ip_port_displayed_LI](https://user-images.githubusercontent.com/98486154/160494990-45b3c338-4995-4950-ba51-94b5c748dc76.jpg)


### Initial Deployment of the website


![Kubernetes_deployment_screenshot1](https://user-images.githubusercontent.com/98486154/160494381-c4989be2-badd-4a16-a8f3-3116ae1e81e3.jpg)


### After the update on the html code in Docker file which triggered CI/CD pipeline to deploy latest docker image of the website

![Kubernetes_deployment_screenshot_updated_webhook](https://user-images.githubusercontent.com/98486154/160494577-ef79ff81-e6e8-44cc-81c1-2a9a7eec93a1.jpg)









