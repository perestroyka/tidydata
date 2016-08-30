## Tidying accelerometers data script
## all file manipulations are done in "./dataset/" directory
## resulting tidy dataset will be written to ./dataset/tidy.txt

library(data.table)
library(dplyr)
library(tidyr)

url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

#hardcoding all the needed files from dataset
file_names=c(    
        "activity_labels.txt",
        "features.txt",
        "subject_test.txt",
        "subject_train.txt",
        "X_test.txt",
        "X_train.txt",
        "y_test.txt",
        "y_train.txt"       
        )

#removing extensions for file names, will be used for generating variable names
var_names <- gsub(".txt","",file_names) 

wd <- getwd()

# Downloading and unzipping the data if not done already
# archive subdirs are skipped to make our life a bit easier and not to bother with file.path()
if(!dir.exists("dataset")) dir.create("dataset")
setwd("dataset")
if(!file.exists("dataset.zip")) { 
        download.file(url,"dataset.zip") 
        unzip("dataset.zip", files=file_names, junkpaths = TRUE,overwrite=FALSE)
        } else {print("Dataset exists, no need to download")}

# loading all files into corresponding variables, might be lengthy, so made progress output to improve UX :)
for (i in 1:length(var_names)) {
        print(paste("Loading:",i,"of",length(var_names), file_names[i]),quote=FALSE)
        assign(var_names[i],fread(file_names[i]))
        }

#prepping the list with mean() and std() variables names and its column indices
var_names_useful <- grep("(std\\(\\))|(mean\\(\\))",features$V2,value=TRUE)
var_index_useful <- grep("(std\\(\\))|(mean\\(\\))",features$V2)

# removing parenthesis from var_names and replacing dashes with underscores
var_names_useful <- mapply(gsub,"\\(\\)","", var_names_useful)
var_names_useful <- mapply(gsub,"-","_", var_names_useful)

#converting activities to factor variables with meaningful labels
y_train <- factor(y_train$V1,labels=activity_labels$V2)
y_test <- factor(y_test$V1,labels=activity_labels$V2)

X_test$Activity <- y_test
X_test$Subject <- subject_test
X_train$Activity <- y_train
X_train$Subject <- subject_train

X_joined <- full_join(X_test,X_train)           #Joining X_test & X_train
X_joined <- select(X_joined,c(var_index_useful,Activity,Subject))   #Cutting all the unnecessarry columns
X_joined$Subject <- factor(X_joined$Subject,levels=unique(X_joined$Subject),labels=unique(paste0("Subject#",X_joined$Subject)))

#giving descriptive names to variables
names(X_joined) <- c(var_names_useful,"Activity","Subject")

#making new data set with averages of std() and mean () variables grouped by Subject and Activity
by_activity <- X_joined %>% 
        select(-Subject) %>%
        group_by(Activity) %>%
        summarize_all(mean)
by_activity <- rename(by_activity,Activity_or_Subject=Activity)
by_subject <- X_joined %>% 
        select(-Activity) %>%
        group_by(Subject) %>%
        summarize_all(mean)
by_subject <- rename(by_subject,Activity_or_Subject=Subject)
tidy <- rbind(by_activity,by_subject)

write.table(tidy,"tidy.txt",row.name=FALSE) #writing tidy data set

setwd(wd) #restoring working directory