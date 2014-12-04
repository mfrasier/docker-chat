FROM dockerfile/java:oracle-java7
ADD stomp-chat-3.0.0.BUILD-SNAPSHOT.jar /app/
EXPOSE 8080
ENTRYPOINT ["/usr/bin/java", "-jar", "/app/stomp-chat-3.0.0.BUILD-SNAPSHOT.jar"]
