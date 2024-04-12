

gh auth
for i in `gh repo list LinkeIT -L 10000 --json name | jq -r '.[].name'`
do 
  echo git clone git@github.com:LinkeIT/$i
done



glab auth login

for i in `glab repo list -P 1000|awk '{ print $2 }'|wc -l`
do 
  echo git clone $i
done

