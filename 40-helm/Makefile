install:
	helm upgrade -i frontend roboshop -f values/frontend.yml
	helm upgrade -i catalogue roboshop -f values/catalogue.yml

uninstall:
	helm uninstall frontend catalogue
