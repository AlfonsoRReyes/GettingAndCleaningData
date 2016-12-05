# CodeBook.md


We start by downloading the zipped file containing all the datasets and associated files.
We load the library `downloader` to allow us the use of the function `download()`.

Since we want to make this analysis reproducible, we added the capability of detecting if the folder `data` exists in the folder structure. If it doesn't exist, the script will create it for the user.


```r
library(downloader)

if(!file.exists("./data")){dir.create("./data")}

fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

download(fileUrl, dest="dataset.zip", mode="wb") 
unzip ("dataset.zip", exdir = "./data")
```

