 This script takes 2 github repositories with their branches specified after link.
 first link has to be python code repository, which gets cloned and tested by pytest and black.
 second link has to be a repository which will be a storage for pytest and black test results, followed by branch name to where we upload


 ### script launching example
 
 sh midterm.sh https://github.com/levan-bujiashvili-1-btu-edu-ge/gitMidterm1test master https://github.com/levan-bujiashvili-1-btu-edu-ge/midtermReport main

### for code to function

 create file in main directory called ".env" without quotation marks and add your personal access key into it. (see .env example)