cd ~/Tools/QiNiu
qshell -m qupload config
qshell -m listbucket xiazuomo list
cat list | awk '{print "ougxj11md.bkt.clouddn.com/"$1}' >final
sudo gedit final
