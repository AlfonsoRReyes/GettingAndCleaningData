

run_ana <- function() {
  library(dplyr)
  library(stringr)
  
  # load measurement data files
  
  # train
  train_measurements_raw <<- raw_measurements_data("train")$measurements
  train_activities_raw   <- raw_measurements_data("train")$activities 
  train_subjects_raw     <- raw_measurements_data("train")$subjects 
  
  # test
  test_measurements_raw <<- raw_measurements_data("test")$measurements
  test_activities_raw   <- raw_measurements_data("test")$activities 
  test_subjects_raw     <- raw_measurements_data("test")$subjects 
  
  # load variable names or features
  fileName <- "./data/UCI HAR Dataset/features.txt"
  valid_column_names <<- compose_features(fileName)
  
  # assign correct variable names to measurement data frames
  
  # add column names to measurements. assign features to variables in measurements datasets
  train_measurements <<- assign_valid_names(train_measurements_raw, valid_column_names)
  
  test_measurements  <<- assign_valid_names(test_measurements_raw, valid_column_names)
  
  # Keep only mean and std-dev variables in measurements dataset 
  
  keywords <- c("mean", "std")
  train_measurements_select <<- select_columns_with_expression(train_measurements, keywords)
  
}



select_columns_with_expression <- function(df, keywords) {
  
  # Keep only mean and std-dev variables in measurements dataset 
  matchExpression <- paste(keywords, collapse = "|")                           # pattern of keywords mean, std
  df_ret <- select(df, matches(matchExpression, ignore.case = TRUE))   # select columns that match mean, std
  return(df_ret)
}


assign_valid_names <- function(df, new_names) {
  # Called by: run_ana()
  # assign correct variable names to data frame
  names(df) <- new_names
  df
}


raw_measurements_data <- function(ds_name) {
  # read raw data sets
  measurements_fn <- "./data/UCI HAR Dataset/file/X_file.txt"
  activities_fn   <- "./data/UCI HAR Dataset/file/y_file.txt"
  subjects_fn     <- "./data/UCI HAR Dataset/file/subject_file.txt"
  
  ds_files_v <- c(measurements_fn, activities_fn, subjects_fn)   # a vector of files to read
  ds_files   <- gsub("file", ds_name, ds_files_v)                # switch the identifier "_file" by "_train" or "_test"
  
  mea <- read.table(ds_files[1])
  act <- read.table(ds_files[2])
  sub <- read.table(ds_files[3])
  
  list(measurements=mea, activities=act, subjects=sub)
  
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
  list(all_rows=all_rows, duplicates=duplicate_rows)    # create a list for nice reporting later
  
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
  # Called by:         compose_features()
  #
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
  # Called by:     make_nice_variables()
  #
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


duplicates  <- function(vec) {
  # Called by: compose_features()
  #
  # Detects variable names that are duplicate
  #
  # vec:     character vector or column from a table to analyze
  # return:  integer
  #          number of rows that are duplicate
  duplicate_rows <- length(vec[(duplicated(vec) | duplicated(vec, fromLast = TRUE))])  
}