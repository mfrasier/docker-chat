docker-chat
===========

docker container running spring integration sample application stomp-chat

We've decided to use [docker](http://docker.io) containers to package and deploy application components as nano services.  This post documents initial experimentation to build and run a sample application as a service.

The application is a [spring integration](http://projects.spring.io/spring-integration/) stomp over websockets chat sample app.  It is a java application running in an embedded tomcat container, packaged as a stanadalone (uber) jar.

This type of application seems to be a great fit for a docker container
 
 * self-contained; includes dependencies
 * provides a service
 * consists of one process
 * can be used by other services (or people but we'll pretend it's a messaging service for our applications)

<!-- more -->

#### install docker
I'm using OS X so I used the installation instructions found [here](https://docs.docker.com/installation/mac/).  Be sure to do the boot2docker bit.

Use whatever is appropriate for your OS.

#### get application code
I'm using Spring integration samples from [here](https://github.com/SpringSource/spring-integration-samples). 
I cloned the git repo locally using 
```
git clone git@github.com:spring-projects/spring-integration-samples.git ~/spring-integration-samples
```

Modify the index.html a bit so the host:port are not hard-coded:
```
diff --git a/applications/stomp-chat/src/main/resources/static/index.html b/applications/stomp-chat/src/main/resources/static/index.html
index 9add0e0..2e99b6e 100644
--- a/applications/stomp-chat/src/main/resources/static/index.html
+++ b/applications/stomp-chat/src/main/resources/static/index.html
@@ -1,8 +1,8 @@
 <html>
 <head>
     <title>WebSocket Chat</title>
-    <script src="http://localhost:8080/sockjs.js"></script>
-    <script src="http://localhost:8080/stomp.js"></script>
+    <script src="/sockjs.js"></script>
+    <script src="/stomp.js"></script>
     <script type="text/javascript">

         var sock, stompClient, currentUser, subscriptions = {};
@@ -11,7 +11,7 @@
             var userValue = document.getElementById('user');
             if (userValue.value != "") {
                 currentUser = userValue.value;
-                sock = new SockJS('http://localhost:8080/chat');
+                sock = new SockJS('/chat');
                 stompClient = Stomp.over(sock);
```

#### run code locally
from <code>~/spring-integration-samples</code> directory run 
```
./gradlew stomp-chat:run
```

using a browser point to http://localhost:8080/ and play with the app.

#### build uber jar
```
./gradlew stomp-chat:build
```
will build and test the app.

The file we will use is <code>applications/stomp-chat/build/libs/stomp-chat-3.0.0.BUILD-SNAPSHOT.jar</code>

#### build docker image
Make new empty directory for the Dockerfile and context (files destined for image) and copy the jar file there.

```
mkdir ~/docker-chat; cd $_
cp ~/spring-integration-samples/applications/stomp-chat/build/libs/stomp-chat-3.0.0.BUILD-SNAPSHOT.jar .
```

##### Dockerfile

create Dockerfile and populate with these lines:
```
FROM dockerfile/java:oracle-java7
ADD stomp-chat-3.0.0.BUILD-SNAPSHOT.jar /app/
EXPOSE 8080
ENTRYPOINT ["/usr/bin/java", "-jar", "/app/stomp-chat-3.0.0.BUILD-SNAPSHOT.jar"]
```

Those instructions tell docker to 

 * use a base image that has java installed
 * copy our jar file into the /app directory (creating the directory if needed)
 * make port 8080 available for mapping
 * execute the jar file when the container is started

##### create docker image
On OS X I need to point at my docker vm to communicate with the daemon.  I can get the necessary environment variable exports using 
```
boot2docker shellinit
Writing /Users/mfrasier/.boot2docker/certs/boot2docker-vm/ca.pem
Writing /Users/mfrasier/.boot2docker/certs/boot2docker-vm/cert.pem
Writing /Users/mfrasier/.boot2docker/certs/boot2docker-vm/key.pem
    export DOCKER_HOST=tcp://192.168.59.103:2376
    export DOCKER_CERT_PATH=/Users/mfrasier/.boot2docker/certs/boot2docker-vm
    export DOCKER_TLS_VERIFY=1
```
Copy the export commands and paste in shell to execute.

##### Build the image
```
docker build -t mfrasier/stomp-chat .
Sending build context to Docker daemon 56.79 MB
Sending build context to Docker daemon
Step 0 : FROM dockerfile/java:oracle-java7
 ---> 8fb1905f5b5e
Step 1 : ADD stomp-chat-3.0.0.BUILD-SNAPSHOT.jar /app/
 ---> Using cache
 ---> 5fa52eb71231
Step 2 : EXPOSE 8080
 ---> Using cache
 ---> 940aae24f7bc
Step 3 : ENTRYPOINT /usr/bin/java -jar /app/stomp-chat-3.0.0.BUILD-SNAPSHOT.jar
 ---> Using cache
 ---> b05640830c5b
Successfully built b05640830c5b
```

The -t switch tags the image with a name used later to reference the image.

Verify the image exists
```
docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
mfrasier/stomp-chat   latest              b05640830c5b        23 hours ago        754.2 MB
```

#### create and a run docker container from the image
```
docker run -p 8080:8080 -d --name chat1 mfrasier/stomp-chat
882ee0e51db9c809906e2f577a56714413bb4daa0d6213ecaa3ba51b23d8ebc8
```
The run command returns the container id.
We should now have a running container which has mapped it's port 8080 to the vm port 8080 (that's what the -p switch does).
The -d switch tells the container to run detached.
The --name switch gives the container a name we can use to reference it, besides the id.

We can verify the container is running with the docker ps command.
```
docker ps
CONTAINER ID        IMAGE                        COMMAND                CREATED             STATUS              PORTS                    NAMES
882ee0e51db9        mfrasier/stomp-chat:latest   "/usr/bin/java -jar    22 hours ago        Up About a minute   0.0.0.0:8080->8080/tcp   chat1
```

#### test app running in container
on my host the docker vm is at IP address <code>192.168.59.103</code> so I point my browser to <code>http://192.168.59.103:8080</code> to test the app.  Be sure to login from multiple browser pages as different people to get the full effect!

