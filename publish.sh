
function pushAndRelease() {	
	echo $1

	git add .
	git commit -m "Bumped version to $1"

	# git push

	# pushRes=$?
	# echo '将代码推入到远程分支息->' + $pushRes

	# if [ $pushRes = '1' ] ; then
	#   echo '代码有冲突， 请在本地修改，修改完继续执行此条命令 bash bash.sh'
	#   return
	# fi

	# echo 'hhhh'
}

pushAndRelease $1
