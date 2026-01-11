install:
	chmod +x setup.sh
	sudo ./setup.sh

update:
	chmod +x update.sh
	./update.sh

uninstall:
	chmod +x uninstall.sh
	sudo ./uninstall.sh

status:
	systemctl status recieverServer

logs:
	journalctl -u recieverServer -f
