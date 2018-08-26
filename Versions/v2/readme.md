Importent Deps:
sudo apt-get install curl
sudo apt-get install pigz
sudo apt install default-jre

The .jar file takes at least one and up to three command line arguments:

java -cp com.semangit_main.jar Mainass <path/to/input/directory> [-base=X] [-noprefix]
Where X can be one of: 64, 32, 16 or 10. -noprefix enforces the usage of -base=10.
