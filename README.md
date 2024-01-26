# disklog
Introducing Disklog, a powerful script that simplifies the process of collecting, analyzing and troubleshooting crucial hard drive information in a Windows Storage Space environment. Its lightweight and user-friendly design makes it easy to gather the necessary data, providing a smooth experience. With Disklog, you can quickly and easily identify and resolve hard drive related issues, ensuring the health and performance of your hard drives.

To use Disklog, you can follow these steps:

1. Run the command below in PowerShell elevate mode (COPY & PASTE)

md C:\Dell -Force
Set-ExecutionPolicy -scope Process -ExecutionPolicy RemoteSigned -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-BitsTransfer https://raw.githubusercontent.com/wpshell/disklog/main/disklog.ps1 -Destination c:\Dell\disklog.ps1
C:\Dell\disklog.ps1

2. Allow the script to run for a period of 3-5 minutes to collect the log file
3. The log file will be generated with a name based on the date and time of execution, for example 'C:\Dell\20211007-222352.zip'

Alternatively, you can also follow these steps:
1. Copy the script to a Windows Storage Space node (e.g. C:\Dell)
2. Open PowerShell in Administrator mode and execute the command '.\disklog.ps1'
3. Allow the script to run for a period of 3-5 minutes to collect the log file
4. The log file will be generated with a name based on the date and time of execution, for example 'C:\Dell\20211007-222352.zip'

With either method, you can be confident that you have the necessary data to troubleshoot and resolve any hard drive related issues within your Windows Storage Space environment with ease. The first method is an online alternative way to download the script, whereas the second method is using the local copy of the script.
