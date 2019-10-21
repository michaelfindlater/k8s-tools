# AUTHOR: github.com/michaelfindlater

# Reveals secrets in clear text
krevealsecret() {
    kubectl get secret "$1" -o json | jq '.data | map_values(@base64d)'
}

# Helps encoding strings and files as base64 secrets
kchangesecret() {
    case $3 in
        "-f")  # File
            BASE64_VALUE=$(cat $4 | base64 | tr -d "\n")
            ;;
        "-s")  # String
            BASE64_VALUE=$(echo -ne $4 | base64)
            ;;
        *)
            echo -e "Usage:\n\tkchangesecret secret-name yaml-key [-f | -s] filename-or-string"
            echo "i.e.:"
            echo -e "\tkchangesecret my-secret my-key -f my-file.txt"
            echo -e "\tkchangesecret my-secret my-key -s my-string"
            ;;
    esac
    if [ $BASE64_VALUE ]; then
    	SUB="s/(\s*$2:)\s*(:?.)*$/\1 $BASE64_VALUE/"
	YAML=$(kubectl get secret $1 -o yaml)
	BEFORE=$(echo "$YAML" | egrep -o "(\s*$2:)\s*(:?.)*$")
	AFTER=$(echo "$BEFORE" | sed -r "$SUB")
	echo "Editing secret '$1'."
	echo -e "\nBefore:\n$BEFORE"
	echo -e "\nAfter:\n$AFTER\n"
	while true; do
	    read -p "Continue? (y/n): " yn
	    case $yn in
	        [yY]* ) kubectl get secret $1 -o yaml | sed -r "$SUB" | kubectl apply -f - && break;;
	        [nN]* ) break;;
            esac
	done
    fi
}
