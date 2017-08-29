host=http://www.t2dream-demo.org/file
key=********:****************

curl -u $key --request POST -d @- --header 'Content-Type:application/json'  $host
