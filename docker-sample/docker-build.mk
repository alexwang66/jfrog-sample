docker login server.jfrog.io
docker tag jas-demo:v3 server.jfrog.io/alex-docker-local/jas-demo:v3
jf docker push server.jfrog.io/alex-docker-local/jas-demo:v3 --build-name=jas-demo \
  --build-number=3
jf rt bp jas-demo 3 
