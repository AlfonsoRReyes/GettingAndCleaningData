# run_analysis.R

run_ana <- function() {
  library(dplyr)
  library(stringr)

  
# 1. merge the training and test datasets
  # read train
  # read test
  # add variable <source> to each data set to identify the original table
  # merge train and test
  # read variable names from features table
  # assign variable names to merged table
    # create valid names
    # assign valid names to merged table
# 2. Extract only the man and std-deviation
  # choose only mean and std-dev variables
# 3. Use descriptive names for activities
  # read and assign activities
  # read and assign subjects
  # ---------------------------------------------------------------------------
  if(!file.exists("./data")){dir.create("./data")}
  
  library(downloader)
  
  fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
  # download(fileUrl, dest="dataset.zip", mode="wb") 
  # unzip ("dataset.zip", exdir = "./data")
  

# read common tables such as activity labels and features (column names for measurements)
  
  # read variable/column names. Also called features. 561 elements.
  # rows:  561. Matches the number of columns in the measurement datasets
  # V1:    record number
  # V2:    variable name or feature
  fileName <- "./data/UCI HAR Dataset/features.txt"
  
  # ensure valid names for the variables. Making valid_column_names GLOBAL
  # will read a table of the variable names after clean up
  # rows:             561
  # columns:          1 (returning as character vector)
  # name of column:   nice
  # env:              global
  # characteristics:  variable names. No parentheses, no duplicates, no dashes, no dots
  valid_column_names <<- compose_features(fileName)
  
  
  # read activity labels. They are 6 activity label variables
  # rows: 6
  # V1:   activity ID
  # V2:   activity description
  # file: "./data/UCI HAR Dataset/activity_labels.txt"
  activity_labels <<- read.table("./data/UCI HAR Dataset/activity_labels.txt")
  
  
# compose measurement datasets using a common function
  # datasets: 2
  # names:    train   test
  # rows:     
  # columns:  
  # read measurement tables for training and testing
  train <<- compose("train")
  test  <<- compose("test")
  
  
  # merge the measurement datasets for training and testing
  # rows:     10299
  # columns:  92
  # contains: (1) measurements for training and tests; (2) subjects; (3) activities
  train_test_merged <<- rbind(train, test) %>%
    mutate(row_num = row_number())      # add row_num to be able to reorder table in the future
  
  # group by subjects and activities
  by_SubjectActivity<- group_by(train_test_merged, subjects_id, activity_name)
  
  # summary showing the mean of mean and std columns by subects and activities
  sum_SubjectActivity <<- summarize_at(by_SubjectActivity, .cols = mean_std_vars,
                             .funs = mean)  
  
  # output of tidy dataset containing summary of subjects and activities 
  # and the mean of selected columns.
  write.table(sum_SubjectActivity, "sum_subjects_activities.txt")
  
}



# compose the main data sets using a function
# ds_name: character
#          the name of the dataset
#
# return: data.frame
#         a data frame after adding valid column names, activities, subjects; and
#         selecting mean and standard deviation columns

compose <- function(ds_name) {
  # read raw data sets
  measurements_fn <- "./data/UCI HAR Dataset/file/X_file.txt"
  activities_fn   <- "./data/UCI HAR Dataset/file/y_file.txt"
  subjects_fn     <- "./data/UCI HAR Dataset/file/subject_file.txt"
  
  ds_files_v <- c(measurements_fn, activities_fn, subjects_fn)   # a vector of files to read
  ds_files   <- gsub("file", ds_name, ds_files_v)                # switch the identifier "_file" by "_train" or "_test"
  
  measurements <- read.table(ds_files[1])
  activities   <- read.table(ds_files[2])
  subjects     <- read.table(ds_files[3])
  
  
  # add column names to measurements. assign features to variables in measurements dataset
  names(measurements) <- valid_column_names           # since valid_column_names is global
  
  # Keep only mean and std-dev variables in measurements dataset 
  matchExpression <- paste(c("mean", "std"), collapse = "|")                           # pattern of keywords mean, std
  measurements <- select(measurements, matches(matchExpression, ignore.case = TRUE))   # select columns that match mean, std
  
  mean_std_vars <<- names(measurements)
  
  # read activity records for measurements for training and testing
  # read subjects records for measurements for training and testing  
  
  # add row numbers to activity table. It will be useful to check the merge or join later
  activities$activity_rownum <- 1:nrow(activities)      # row numbering to column
  activities <- rename(activities, activity_id = V1)    # rename column
  
  # add row number variable to subjects table. It will be useful to check the merge or join later
  subjects <- subjects %>%
    mutate(subjects_rownum = row_number()) %>%          # row numbering to column
    rename(subjects_id = V1)                            # rename column
  
  
  # merge the activity tables (long and descriptive) keeping the original order of test_activity
  activity_merged <- dplyr::inner_join(activities, activity_labels, by =c( "activity_id" = "V1"))
  activity_merged <- dplyr::rename(activity_merged, activity_name = V2) # rename columns
  
  # add a row number column to measurements to be sure it is not sorted by the merge operation
  measurements <- measurements %>%
    mutate(m_rownum = row_number()) %>%   # add a record number to measurements
    select(m_rownum, everything())        # move the row_num column to be the first column
  
  # merge measurements with activity table
  m0 <- cbind(activity_merged, measurements)
  
  # merge new table above with subjects table
  final <- cbind(subjects, m0)
  rm(m0)                                      # remove temporary object
  
  # add a variable to identify the source of the data
  final <- final %>%
    mutate(source = ds_name) %>%                                                                 # new column for source
    # add new column combining source and record number
    mutate(src_rownum = paste0(source, "_", str_pad(as.character(m_rownum), 5, pad = "0"))) %>%  # add column with source and row num
    select(-c(m_rownum, activity_rownum, subjects_rownum))                                       # remove utility columns
  
  # return processed dataframe
  return (final)       
}



compose_features <- function(fileName) {
  # takes care of the proper validation of the variables names
  # features <- read.table("./data/UCI HAR Dataset/features.txt")
  features <- read.table(fileName)
  
  # convert factors to character vector
  features <- features %>%
    mutate(V2 = as.character(V2))
  
  # get counts for all rows and duplicate rows
  all_rows <- nrow(features)
  duplicate_rows <- length(features$V2[(duplicated(features$V2) | duplicated(features$V2, fromLast = TRUE))])
  list(all_rows=all_rows, duplicates=duplicate_rows)
  
  # create features with logical marker for duplicates
  features2 <- features %>%
    mutate(duplicate = FALSE) %>%    # mark the whole new column as FALSE
    mutate(duplicate = (duplicated(V2) | duplicated(V2, fromLast = TRUE)))  # mark TRUE duplicates
  
  # get subset of features. working only with subset of duplicates
  
  getFromLast <- function(y, m) {
    # function that gets the first or second elements -counting from the end-, of a decomposed string
    pat <- "\\,|\\-"                   # pattern is a comma or a dash
    var_list <- strsplit(y, pat)       # split the string by the pattern
    last2 <- data.frame(t(data.frame(sapply(var_list, tail, n=2))))     # get the last two elements of the list
    as.character(last2[, m])    # get character vector all rows, column "m"
  }
  
  fill_axis <- function() {
    # function to fill  rows with corresponding measurement axis
    # get a vector of X, Y, Z every fourteen
    x <- rep("x", 14); y <- rep("y", 14); z <- rep("z", 14); 
    xyz <- rep(c(x,y,z), 3)  
  }
  
  
  # operate on a dataframe of duplicates only
  features_dup <- features2 %>%
    filter(duplicate == TRUE) %>%      # duplicate features or column names
    mutate(lbin = as.integer(getFromLast(as.character(V2), 1))) %>%    # get the first bin set
    mutate(rbin = as.integer(getFromLast(as.character(V2), 2))) %>%    # get the second bin set
    mutate(window = ifelse(abs(lbin-rbin)+1 == 8, "w1", 
                           ifelse(abs(lbin-rbin)+1 == 16, "w2", 
                                  ifelse(abs(lbin-rbin)+1 == 24, "w3", "")))) %>%   # assign the bin windows
    mutate(axis = fill_axis()) %>%                                                  # assign the axis labels
    mutate(V2_new = paste(V2, window, axis, sep="-")) %>%                           # form the full name of the new column
    select(V1, V2_new)                                                              # select the id and the new column name
  
  # merge the original dataframe with the duplicates dataframe
  features_new <- merge(features2, features_dup, by.x = "V1", by.y = "V1", all = TRUE)
  features_new <- mutate(features_new, V2_new = ifelse(duplicate == FALSE, as.character(V2), V2_new))
  
  # convert factors to character vector
  raw_column_names <- as.character(features_new$V2_new)
  
  # ensure there are valid names for the variables. Making valid_column_names GLOBAL
  valid_column_names <<- make.names(names=raw_column_names, unique=TRUE, allow_ = TRUE)
  features_new$V2_valid <- valid_column_names
  
  # convert clean features dataframe to nice variables: no dots, no parentheses, no dash
  nice_variables <- make_nice_variables(features_new$V2_valid)
  features_new$V2_nice <- nice_variables
  
  # find if there are duplicate rows
  duplicate_rows <- duplicates(features_new$V2_nice)
  
  # set new names to final dataframe
  features_new <- features_new %>%      # proceed to rename to something human
    rename(original = V2, isduplicate = duplicate, nonduplicate = V2_new, make = V2_valid, nice = V2_nice)
  
  features_new$nice    # return only one column
}



make_nice_variables <- function(column_names) {
  # Use recommendations for variable names
  # no dots, no dashes, no underscores, no capitalization, no uppercase
  #
  # column_names: character vector
  #               a vector or table column
  # return:       character vector
  var_names <- as.character(column_names)      # convert from factors to character type
  splitNames <- strsplit(var_names, "[.]")     # split in the dot
  s <- sapply(splitNames, noblankElements)     # apply function noblankElements to the list to get nice variable names
}


noblankElements <- function(x) {
  # receives a list of characters that has been split
  # and returns the concatenation of not-blank elements in lowercase
  #
  # x:        character vector
  # returns:  character vector
  (x[(!is.null(x)) & (x != "")]) %>%    # get non empty elements and non blanks in the list
    unlist() %>%                        # unpack the elements in the list
    tolower() %>%                       # convert to lowercase
    paste(collapse = '')                # concatenate valid components of original variable name
}


duplicates <- function(vec) {
  # Detects variable names that are duplicate
  #
  # vec:     character vector or column from a table to analyze
  # return:  integer
  #          number of rows that are duplicate
  duplicate_rows <- length(vec[(duplicated(vec) | duplicated(vec, fromLast = TRUE))])  
}

short_summary <- function(df) {
  # custom short report
  # df:   data frame
  # 
  cat("Observations:", "\t", nrow(df), "\t\t\t")
  cat("First variables:", head(names(df)), "\n")
  cat("Variables:", "\t", length(names(df)), "\t\t\t")
  cat("Last variables:", tail(names(df)), "\n\n")
  #cat("First                                   Middle                           Last\n")
  s <- seq(from=1, to=length(df), length.out = 5 )
  all_names.df <- names(df)
  names.df <- all_names.df[s]
  to_desc <- select(df, one_of(names.df))
  
  cat("First observations\n")
  print(head(to_desc))
  cat("\n")
  cat("Summary of selected variables")
  summary(to_desc)
}
