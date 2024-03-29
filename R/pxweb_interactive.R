#' @title Find and download data interactively from a PXWEB API
#'
#' @description Wrapper function (for \link{pxweb_get}) to simply find and download data to the current R session.
#'
#' @param x The name or alias of the pxweb api to connect to, a \code{pxweb} object or an url.
#'
#' @return
#' The function returns a list with three slots:
#' \code{url}: The URL to the data
#' \code{query}: The query to access the data
#' \code{data}: The downloaded data (if chosen to download data)
#'
#' @seealso
#' \code{\link{pxweb_get}}
#' @export
#' @examples
#' pxweb_api_catalogue() # List apis
#'
#' ## The examples below can only be run in interactive mode
#' ##  x <- pxweb_interactive()
#' ##  x <- pxweb_interactive(x = "api.scb.se")
#' ##  x <- pxweb_interactive(x = "https://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/")
#' ##  x <- pxweb_interactive(x = "https://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/")
#'
pxweb_interactive <- function(x = NULL) {
  # Check internet access if x is an url
  if(!is.null(x)){
    url_parsed <- parse_url(x)
    if(parsed_url_has_hostname(url_parsed)){
      if(!has_internet(url_parsed$hostname)){
        message(no_internet_msg(url_parsed$hostname))
        return(NULL)
      }
    }
  }

  # Setup structure
  pxe <- pxweb_explorer(x)

  if (!pxe$show_history) {
    cat("\014")
  }

  # The main program - build up a query
  while (!pxe$quit) {
    # Generate header
    print(pxe)
    pxe <- pxweb_interactive_input(pxe)


    if (!pxe$show_history & !pxe$quit) {
      cat("\014")
    }
  }

  results <- list(
    url = pxe_data_url(pxe),
    query = pxweb_query(pxe)
  )
  dat <- pxe_interactive_get_data(pxe)

  if (!is.null(dat)) {
    results$data <- dat
  }

  return(invisible(results))
}

#' @rdname pxweb_interactive
#' @export
interactive_pxweb <- function(x = NULL) {
  pxweb_interactive(x)
}

#' Create a \code{pxweb_explorer} object.
#' @param x a \code{pxweb} object, a PXWEB url, \code{NULL} or an api in the api catalogue.
#'
#' @description
#' \code{position} the current position in the api, as a character vector from the root.
#' Note position is not alway a correct url. Metadata and other choices are part of position
#'
#' \code{root} is the bottom path (as position) that the user can go. If length 0, user can essentially go to hostname.
#'
#' paste(root_path + position, collapse = "/")  is used to construct the path to the position
#' in case of url.
#'
#' @examples
#' ## The functions below are internal generic functions
#' ## x <- pxweb_explorer()
#' ## url <- "api.scb.se"
#' ## x <- pxweb_explorer(x = url)
#' ## url <- "https://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/"
#' ## x <- pxweb_explorer(x = url)
#' ## url <- "https://api.scb.se/OV0104/v1/doris/en/ssd/BE/BE0101/BE0101A/BefolkningNy"
#' ## x <- pxweb_explorer(x = url)
#'
#' @keywords internal
pxweb_explorer <- function(x = NULL) {
  UseMethod("pxweb_explorer")
}

#' @rdname pxweb_explorer
#' @keywords internal
pxweb_explorer.NULL <- function(x) {
  apis <- pxweb_api_catalogue()
  pxe <- list(
    pxweb = NULL,
    root = character(0)
  )
  pxe$position <- character(0)
  pxe$variable_choice <- list()
  pxalist <- list()
  txt <- unname(unlist(lapply(apis, function(x) x$description)))
  for (i in seq_along(names(apis))) {
    pxalist[[i]] <- list(id = names(apis)[i], type = "l", text = txt[i])
  }
  pxl <- pxweb_levels(pxalist)
  pxe$pxobjs <- list("/" = list(pxobj = pxl))
  class(pxe) <- c("pxweb_explorer", "list")
  pxe <- add_pxe_defaults(pxe)
  assert_pxweb_explorer(pxe)
  pxe
}

#' @rdname pxweb_explorer
#' @keywords internal
pxweb_explorer.character <- function(x) {
  apis <- pxweb_api_catalogue()
  api_alias_tbl <- pxweb_api_catalogue_alias_table()
  px <- try(pxweb(x), silent = TRUE)
  if (inherits(px, "try-error")) {
    pos_idx <- which(api_alias_tbl$alias %in% x)
    if (length(pos_idx) == 0) {
      stop("'", x, "' is not a PXWEB API. See pxweb_api_catalogue() for available PXWEB APIs.", call. = FALSE)
    }
    px <- apis[[api_alias_tbl$idx[pos_idx]]]
  }
  pxweb_explorer(px)
}

#' @rdname pxweb_explorer
#' @keywords internal
pxweb_explorer.pxweb <- function(x) {
  pxe <- list(pxweb = x)
  pxe$root <- pxweb_api_subpath(pxe$pxweb, as_vector = TRUE)
  pxe$position <- pxweb_api_path(pxe$pxweb, as_vector = TRUE)
  pxe$variable_choice <- list()
  class(pxe) <- c("pxweb_explorer", "list")
  pxe <- add_pxe_defaults(pxe)
  assert_pxweb_explorer(x = pxe)
  pxe_pxobj_at_position(pxe) <-
    pxweb_get(pxe_position_path(pxe, include_rootpath = TRUE))
  pxe
}

#' @rdname pxweb_explorer
#' @keywords internal
pxweb_explorer.pxweb_api_catalogue_entry <- function(x) {
  suppressMessages(pxe <- list(pxweb = pxweb(build_pxweb_url(x))))
  if(is.null(pxe$pxweb)) {
    stop(no_internet_msg(parse_url(x$url)$hostname),
         call. = FALSE)
  }
  tot_pos <- pxweb_api_path(pxe$pxweb, as_vector = TRUE)
  pxe$root <- character(0)
  pxe$position <- character(0)
  pxe$variable_choice <- list()

  tot_pos <- strsplit(httr::parse_url(x$url)$path, split = "/")[[1]]
  ver_pos <- which(tot_pos == "[version]")
  lan_pos <- which(tot_pos == "[lang]")
  version_list <- list()
  for (i in seq_along(x$version)) {
    version_list[[i]] <- list(
      id = gsub("\\[version\\]", paste(tot_pos[1:ver_pos], collapse = "/"), replacement = x$version[i]),
      type = "l",
      text = x$version[i]
    )
  }
  pxe$pxobjs <- list("/" = list(pxobj = pxweb_levels(version_list)))

  language_list <- list()
  for (i in seq_along(x$version)) {
    language_list[[i]] <- list()
    for (j in seq_along(x$lang)) {
      lan_part <- gsub("\\[lang\\]", paste(tot_pos[(ver_pos + 1):length(tot_pos)], collapse = "/"), replacement = x$lang[j])
      language_list[[i]][[j]] <- list(
        id = lan_part,
        type = "l",
        text = x$lang[j]
      )
    }
    pxobj_nm <- paste0("/", version_list[[i]]$id)
    pxe$pxobjs[[pxobj_nm]] <- list(pxobj = pxweb_levels(language_list[[i]]), parent = "/")
  }
  class(pxe) <- c("pxweb_explorer", "list")
  pxe <- add_pxe_defaults(pxe)
  assert_pxweb_explorer(x = pxe)
  pxe
}

#' Add default values to pxe
#' @param pxe a \code{pxweb_explorer} object
#' @keywords internal
add_pxe_defaults <- function(pxe) {
  checkmate::assert_class(pxe, "pxweb_explorer")
  pxe$show_history <- FALSE
  pxe$quit <- FALSE
  pxe$print_all_choices <- FALSE
  pxe$print_no_of_choices <- 4
  pxe$show_id <- FALSE
  pxe$metadata <- list(
    position = character(0),
    choices = list()
  )
  pxe
}


#' @rdname pxweb_explorer
#' @keywords internal
assert_pxweb_explorer <- function(x) {
  checkmate::assert_class(x, "pxweb_explorer")
  checkmate::assert_character(x$root)
  checkmate::assert_character(x$position)
  checkmate::assert_subset(x = x$root, x$position)
  checkmate::assert_list(x$metadata)
  checkmate::assert_character(x$metadata$position)
  checkmate::assert_list(x$metadata$choices)
  checkmate::assert_list(x$variable_choice)
  checkmate::assert_flag(x$show_history)
  checkmate::assert_flag(x$print_all_choices)
  checkmate::assert_flag(x$quit)
  checkmate::assert_flag(x$show_id)
  checkmate::assert_int(x$print_no_of_choices, lower = 1)
  for (i in seq_along(x$pxobjs)) {
    checkmate::assert_names(names(x$pxobjs[[i]]), must.include = "pxobj")
    is_pxlev <- inherits(x$pxobjs[[i]]$pxobj, "pxweb_levels")
    is_pxmd <- inherits(x$pxobjs[[i]]$pxobj, "pxweb_metadata")
    checkmate::assert_true(is_pxlev | is_pxmd)
    if (!is.null(x$pxobjs[[i]]$parent)) {
      checkmate::assert_string(x$pxobjs[[i]]$parent)
      checkmate::assert_choice(x$pxobjs[[i]]$parent, names(x$pxobjs))
    }
  }
}


#' @param include_rootpath Should the rootpath be included? Default is FALSE
#' @rdname pxweb_api_name
#' @keywords internal
pxe_position_path <- function(x, init_slash = TRUE, as_vector = FALSE, include_rootpath = FALSE) {
  checkmate::assert_class(x, "pxweb_explorer")
  checkmate::assert_flag(init_slash)
  checkmate::assert_flag(as_vector)
  checkmate::assert_flag(include_rootpath)

  if (is.null(x$pxweb)) {
    if (init_slash) {
      return("/")
    } else {
      return("")
    }
  }
  if (as_vector) {
    if (include_rootpath) {
      return(c(pxweb_api_rootpath(x), x$position))
    } else {
      return(x$position)
    }
  }
  p <- paste(x$position, collapse = "/")
  if (include_rootpath) {
    return(pxweb_fix_url(paste(pxweb_api_rootpath(x), p, sep = "/")))
  } else {
    if (init_slash) {
      return(pxweb_fix_url(paste("/", p, sep = "")))
    }
  }
  return(pxweb_fix_url(p))
}

#' @rdname pxweb_api_name
#' @keywords internal
pxe_metadata_path <- function(x, as_vector = FALSE) {
  checkmate::assert_class(x, "pxweb_explorer")
  checkmate::assert_flag(as_vector)
  if (as_vector) {
    x$metadata$position
  } else {
    paste(x$metadata$position, collapse = "")
  }
}


#' @rdname pxweb_explorer
#' @keywords internal
print.pxweb_explorer <- function(x, ...) {
  print_bar()
  pxnm <- pxweb_api_name(x)
  if (pxnm == "") {
    cat(" R PXWEB API CATALOGUE:\n")
  } else {
    cat(" R PXWEB: Content of '", pxweb_api_name(x), "'\n", sep = "")
  }

  sp <- pxe_position_path(x, init_slash = TRUE, include_rootpath = FALSE)
  if (nchar(sp) > 1) cat("          at '", sp, "'\n", sep = "")
  titl <- pxe_position_title(x)
  if (pxe_position_is_metadata(x)) {
    if (nchar(titl) > 1) cat("   TABLE: ", titl, "\n", sep = "")
    meta_pos <- length(pxe_metadata_path(x, as_vector = TRUE))
    mp <- pxe_metadata_variable_names(x)
    mp[meta_pos] <- paste("[[", mp[meta_pos], "]]", sep = "")
    mp <- paste(mp, collapse = ", ")
    cat("VARIABLE: ", mp, "\n", sep = "")
  }
  print_bar()
  pxe_print_choices(x)
  print_bar()
}

#' Get the table title for the current position
#' @param x a \code{pxweb_explorer} object.
#' @keywords internal
pxe_position_title <- function(x) {
  checkmate::assert_class(x, "pxweb_explorer")
  if (pxe_position_is_metadata(x)) {
    obj <- pxe_pxobj_at_position(x)
    return(obj$title)
  } else {
    return("")
  }
}

#' @rdname pxweb_explorer
#' @description print out a bar for separation purposes
#' @keywords internal
print_bar <- function() {
  cat(rep("=", round(getOption("width") * 0.95)), "\n", sep = "")
}

#' @rdname pxweb_explorer
#' @keywords internal
pxe_print_choices <- function(x) {
  checkmate::assert_class(x, "pxweb_explorer")
  obj <- pxe_pxobj_at_position(x)
  show_no <- x$print_no_of_choices

  if (pxe_position_is_metadata(x)) {
    mddims <- pxweb_metadata_dim(pxe_pxobj_at_position(x))
    md_pos <- pxe_metadata_path(x, as_vector = TRUE)
    no_rows_to_print <- unname(mddims[md_pos[length(md_pos)]])
    choices_idx <- 1:no_rows_to_print
  } else {
    choices_df <- pxweb_levels_choices_df(obj)
    no_rows_to_print <- nrow(choices_df)
    choices_idx <- choices_df$choice_idx
  }

  if (x$print_all_choices | no_rows_to_print <= show_no * 2) {
    print_idx <- 1:no_rows_to_print
  } else {
    print_idx <- c(1:show_no, NA, (no_rows_to_print - show_no + 1):no_rows_to_print)
  }

  print_idx_char <- as.character(print_idx)
  choice_idx_char <- as.character(choices_idx)
  choice_idx_char_nmax <- max(nchar(choice_idx_char), na.rm = TRUE)
  choice_idx_char <- str_pad(choice_idx_char, choice_idx_char_nmax)

  for (i in seq_along(print_idx)) {
    if (is.na(print_idx[i])) {
      cat("\n")
      next
    }

    if (pxe_position_is_metadata(x)) {
      if (x$show_id) {
        cat(" [", print_idx_char[i], " ] : ", obj$variables[[length(md_pos)]]$valueTexts[print_idx[i]], " (", obj$variables[[length(md_pos)]]$values[print_idx[i]], ")", "\n", sep = "")
      } else {
        cat(" [", print_idx_char[i], " ] : ", obj$variables[[length(md_pos)]]$valueTexts[print_idx[i]], "\n", sep = "")
      }
    } else {
      if (obj[[print_idx[i]]]$type == "h") {
        txt <- paste("\n", paste(rep(" ", nchar(print_idx_char[i]) + 2 + 6), collapse = ""), collapse = "")
      } else {
        txt <- paste0(" [", choice_idx_char[print_idx[i]], " ] : ")
      }
      txt <- paste0(txt, obj[[print_idx[i]]]$text)
      if (x$show_id) txt <- paste0(txt, " (", obj[[print_idx[i]]]$id, ")")
      txt <- paste0(txt, "\n")
      cat(txt)
    }
  }
}


#' Pad a string to a fixed size
#' @param txt a character vector to pad
#' @param n final char width
#' @param pad pad symbol
#' @param type pad from 'left' or 'right'.
#' @keywords internal
str_pad <- function(txt, n = 5, pad = " ", type = "left") {
  checkmate::assert_character(txt)
  checkmate::assert_string(pad)
  checkmate::assert_true(nchar(pad) == 1)
  checkmate::assert_int(n)
  checkmate::assert_choice(type, c("left", "right"))

  nch <- pmax((n - nchar(txt)), rep(0, length(txt)))
  nch[is.na(nch)] <- 2
  pads <- unlist(lapply(nch, function(x, pad) {
    paste(rep(pad, x), collapse = "")
  }, pad))
  if (type == "left") {
    return(paste(pads, txt))
  } else {
    return(paste(txt, pads))
  }
}


#' Get input from user
#' @param pxe a \code{pxweb_explorer} object to get user input for.
#' @param test_input supplying a test input (for testing only).
#' @keywords internal
pxweb_interactive_input <- function(pxe, test_input = NULL) {
  checkmate::assert_class(pxe, "pxweb_explorer")
  allowed_input <- pxe_allowed_input(pxe)
  user_input <- pxe_input(allowed_input, test_input = test_input)
  pxe <- pxe_handle_input(user_input, pxe)
  pxe
}

#' Handle a user input for a \code{pxweb_explorer} object.
#' @param pxe a \code{pxweb_explorer} object to get user input for.
#' @param user_input an (allowed) user input to handle.
#' @seealso pxe_allowed_input()
#' @keywords internal
pxe_handle_input <- function(user_input, pxe) {
  checkmate::assert_class(pxe, "pxweb_explorer")
  UseMethod("pxe_handle_input")
}

#' @rdname pxe_handle_input
#' @keywords internal
pxe_handle_input.numeric <- function(user_input, pxe) {
  obj <- pxe_pxobj_at_position(pxe)
  if (pxe_position_is_metadata(pxe)) {
    pxe_metadata_choices(pxe) <- user_input
  } else if (pxe_position_is_api_catalogue(pxe)) {
    pxe <- pxweb_explorer(obj[[user_input]]$id)
  } else {
    cdf <- pxweb_levels_choices_df(obj)
    choice_input <- which(cdf$choice_idx == user_input)
    new_pos <- obj[[choice_input]]$id
    pxe <- pxe_add_position(pxe, new_pos)
  }
  assert_pxweb_explorer(pxe)
  pxe
}

#' @rdname pxe_handle_input
#' @keywords internal
pxe_handle_input.character <- function(user_input, pxe) {
  user_input_ok <- FALSE
  if (user_input == "b") {
    pxe <- pxe_back_position(pxe)
    user_input_ok <- TRUE
  }

  if (user_input == "i") {
    pxe$show_id <- !pxe$show_id
    user_input_ok <- TRUE
  }

  if (user_input == "a") {
    pxe$print_all_choices <- !pxe$print_all_choices
    user_input_ok <- TRUE
  }

  if (user_input == "*") {
    user_input <- 1:pxe_position_choice_size(pxe)
    return(pxe_handle_input(user_input, pxe))
  }

  if (user_input == "e") {
    pxe_metadata_choices(pxe) <- "eliminate"
    user_input_ok <- TRUE
  }

  if (!user_input_ok) stop("Not implemented choice!")

  assert_pxweb_explorer(pxe)
  pxe
}


#' Get and set pxe_metadata_coices
#' @param x a \code{pxweb_explorer} object
#' @param value an object to set as pxe_metadata_choice
#' @keywords internal
pxe_metadata_choices <- function(x) {
  checkmate::assert_class(x, "pxweb_explorer")
  mdc <- x$metadata$choices
  mdcnm <- pxe_metadata_path(x, as_vector = TRUE)
  mdc <- mdc[1:length(mdcnm)]
  names(mdc) <- mdcnm
  mdc
}


#' @rdname pxe_metadata_choices
#' @keywords internal
`pxe_metadata_choices<-` <- function(x, value) {
  checkmate::assert_class(x, "pxweb_explorer")
  checkmate::assert_true(pxe_position_is_metadata(x))
  x$print_all_choices <- FALSE
  mddims <- pxweb_metadata_dim(pxe_pxobj_at_position(x))
  md_pos <- pxe_metadata_path(x, as_vector = TRUE)
  x$metadata$choices[[length(md_pos)]] <- value
  if (length(mddims) > length(md_pos)) {
    x$metadata$position <- names(mddims)[1:(length(md_pos) + 1)]
  } else {
    x$quit <- TRUE
  }
  return(x)
}


#' Move in the \code{pxweb_explorer} position
#'
#' @details \code{pxe_back_position} moves back one position and
#' \code{pxe_add_position} moves forward, based on user choice.
#'
#' @param pxe a \code{pxweb_explorer} object.
#' @param new_pos add a new position.
#' @keywords internal
pxe_back_position <- function(pxe) {
  checkmate::assert_class(pxe, "pxweb_explorer")
  if (pxe_position_is_metadata(pxe) & length(pxe$metadata$position) > 1) {
    pxe$metadata$position <- pxe$metadata$position[-length(pxe$metadata$position)]
    pxe$print_all_choices <- FALSE
    assert_pxweb_explorer(pxe)
    return(pxe)
  }
  pxe$position <- pxe$position[-length(pxe$position)]
  obj <- pxe_pxobj_at_position(pxe)
  if (is.null(obj)) {
    pxe_pxobj_at_position(pxe) <-
      pxweb_get(pxe_position_path(pxe, include_rootpath = TRUE))
  }
  pxe$print_all_choices <- FALSE
  assert_pxweb_explorer(pxe)
  pxe
}

#' @rdname pxe_back_position
#' @keywords internal
pxe_add_position <- function(pxe, new_pos) {
  checkmate::assert_class(pxe, "pxweb_explorer")
  checkmate::assert_string(new_pos)
  pxe$position[length(pxe$position) + 1] <- new_pos
  if (length(pxe$root) == 0 & length(pxe$position) == 2) {
    if (grepl("\\[lang\\]", x = pxe$position[1])) {
      # Special handling of languages (see iceland for example)
      # If lang is also before version, swap that to lang
      pxe$position[1] <- gsub("\\[lang\\]", new_pos, x = pxe$position[1])
      pxe$root <- pxe$position
    }
  }
  obj <- pxe_pxobj_at_position(pxe)
  if (is.null(obj)) {
    pxe_pxobj_at_position(pxe) <-
      pxweb_get(pxe_position_path(pxe, include_rootpath = TRUE))
  }
  pxe$print_all_choices <- FALSE
  assert_pxweb_explorer(pxe)
  pxe
}


#' Get (allowed) inputs for a \code{pxweb_input_allowed} object.
#'
#' @details
#' It handles input and checks if the input is allowed.
#'
#' @param allowed_input a \code{pxweb_input_allowed}.
#' @param title Print (using cat()) before ask for the allowed choices.
#' @param test_input supplying a test input (for testing only)
#' @keywords internal
pxe_input <- function(allowed_input, title = NULL, test_input = NULL) {
  checkmate::assert_class(allowed_input, "pxweb_input_allowed")
  checkmate::assert_string(title, null.ok = TRUE)

  input_ok <- FALSE
  incorrect_choice_no <- 0

  while (!input_ok) {
    if (!is.null(title)) {
      cat(title)
    }
    print(allowed_input)
    if (is.null(test_input)) {
      user_input <- scan(what = character(), multi.line = FALSE, quiet = TRUE, nlines = 1, sep = "\n")
    } else {
      user_input <- test_input
    }
    user_input <- pxe_parse_input(user_input, allowed_input)
    input_ok <- user_input$ok

    # Handle too many incorrect choices
    incorrect_choice_no <- incorrect_choice_no + 1
    if (incorrect_choice_no > 10) {
      stop("Too many incorrect choices. Aborting.", call. = FALSE)
    }
  }
  class(user_input) <- c("pxweb_user_input", "list")
  user_input$input
}


#' @rdname pxe_input
#' @keywords internal
pxe_parse_input <- function(user_input, allowed_input) {
  checkmate::assert_character(user_input)
  checkmate::assert_class(allowed_input, "pxweb_input_allowed")

  if (length(user_input) == 0) {
    cat("Incorrect choice.\n")
    return(list(ok = FALSE))
  }

  ui <- str_trim(user_input)
  if (ui %in% allowed_input$keys$code[allowed_input$keys$allowed]) {
    return(list(ok = TRUE, input = ui))
  }
  if (grepl(x = ui, pattern = "^[:,0-9 ]*$")) {
    if (allowed_input$max_choice == 0) {
      cat("Incorrect choice.\n")
      return(list(ok = FALSE))
    }
    ui <- eval(parse(text = paste("c(", ui, ")")))
    ui <- ui[!duplicated(ui)]
    if (!all(ui %in% 1:allowed_input$max_choice)) {
      cat("Incorrect choice.\n")
      return(list(ok = FALSE))
    }
    if (allowed_input$multiple_choice | length(ui) == 1) {
      return(list(ok = TRUE, input = ui))
    }
  }
  cat("Incorrect choice.\n")
  return(list(ok = FALSE))
}


#' Defines allowed input for a position in a \code{pxweb_explorer} or character object.
#'
#' @param x a object to get allowed input for.
#' @keywords internal
pxe_allowed_input <- function(x) {
  UseMethod("pxe_allowed_input")
}

#' @rdname pxe_allowed_input
#' @keywords internal
pxe_allowed_input_df <- function() {
  input_df <- data.frame(
    code = c("esc", "b", "*", "a", "e", "i", "i", "y", "n"),
    text = c("Quit", "Back", "Select all", "Show all", "Eliminate", "Show id", "Hide id", "Yes", "No"),
    stringsAsFactors = FALSE
  )
  input_df$allowed <- FALSE
  input_df$allowed[1] <- TRUE
  input_df
}

#' @rdname pxe_allowed_input
#' @keywords internal
pxe_allowed_input.pxweb_explorer <- function(x) {
  input_df <- pxe_allowed_input_df()

  input_df$allowed[input_df$code == "esc"] <- TRUE

  if (length(x$position) > length(x$root)) {
    input_df$allowed[input_df$code == "b"] <- TRUE
  }

  if (pxe_position_is_metadata(x)) {
    input_df$allowed[input_df$code == "*"] <- TRUE
    if (pxe_position_variable_can_be_eliminated(x)) {
      input_df$allowed[input_df$code == "e"] <- TRUE
    }
  }

  if (!x$print_all_choices & pxe_position_print_size(x) > x$print_no_of_choices * 2) {
    input_df$allowed[input_df$code == "a"] <- TRUE
  }

  if (x$show_id) {
    input_df$allowed[input_df$text == "Hide id"] <- TRUE
  } else {
    input_df$allowed[input_df$text == "Show id"] <- TRUE
  }

  res <- list(
    keys = input_df,
    multiple_choice = pxe_position_multiple_choice_allowed(x),
    max_choice = pxe_position_choice_size(x)
  )
  class(res) <- c("pxweb_input_allowed", "list")
  assert_pxweb_input_allowed(res)
  res
}


#' @rdname pxe_allowed_input
#' @keywords internal
pxe_allowed_input.character <- function(x) {
  input_df <- pxe_allowed_input_df()
  checkmate::assert_character(x)
  checkmate::assert_subset(x, input_df$code)

  input_df$allowed[input_df$code %in% x] <- TRUE

  res <- list(
    keys = input_df,
    multiple_choice = FALSE,
    max_choice = 0
  )
  class(res) <- c("pxweb_input_allowed", "list")
  assert_pxweb_input_allowed(res)
  res
}

#' @rdname pxe_allowed_input
#' @keywords internal
pxe_allowed_input.pxweb_explorer <- function(x) {
  input_df <- pxe_allowed_input_df()

  input_df$allowed[input_df$code == "esc"] <- TRUE

  if (length(x$position) > length(x$root)) {
    input_df$allowed[input_df$code == "b"] <- TRUE
  }

  if (pxe_position_is_metadata(x)) {
    input_df$allowed[input_df$code == "*"] <- TRUE
    if (pxe_position_variable_can_be_eliminated(x)) {
      input_df$allowed[input_df$code == "e"] <- TRUE
    }
  }

  if (!x$print_all_choices & pxe_position_choice_size(x) > x$print_no_of_choices * 2) {
    input_df$allowed[input_df$code == "a"] <- TRUE
  }

  if (x$show_id) {
    input_df$allowed[input_df$text == "Hide id"] <- TRUE
  } else {
    input_df$allowed[input_df$text == "Show id"] <- TRUE
  }

  res <- list(
    keys = input_df,
    multiple_choice = pxe_position_multiple_choice_allowed(x),
    max_choice = pxe_position_choice_size(x)
  )
  class(res) <- c("pxweb_input_allowed", "list")
  assert_pxweb_input_allowed(res)
  res
}


#' Assert a \code{pxweb_input_allowed} object
#' @param x an object to assert.
#' @keywords internal
assert_pxweb_input_allowed <- function(x) {
  checkmate::assert_class(x, "pxweb_input_allowed")
  checkmate::assert_names(names(x), permutation.of = c("keys", "multiple_choice", "max_choice"))
  checkmate::assert_flag(x$multiple_choice)
  checkmate::assert_int(x$max_choice, lower = 0)
  checkmate::assert_class(x$key, "data.frame")
  checkmate::assert_character(x$key$text)
  checkmate::assert_character(x$key$code)
  checkmate::assert_logical(x$key$allowed)
}

#' @rdname assert_pxweb_input_allowed
#' @keywords internal
print.pxweb_input_allowed <- function(x, ...) {
  if (!x$multiple_choice) {
    cat("Enter your choice:\n")
  } else {
    cat("Enter one or more choices:\n")
    cat("Separate multiple choices by ',' and intervals of choices by ':'\n")
  }
  txt <- paste("(", paste(paste(paste("'", x$keys$code[x$keys$allowed], "'", sep = ""), "=", x$keys$text[x$keys$allowed]), collapse = ", "), ")", sep = "")
  cat(txt, "\n")
}

#' Return the pxweb object at the current position
#' @param x a \code{pxweb_explorer} object.
#' @keywords internal
pxe_pxobj_at_position <- function(x) {
  checkmate::assert_class(x, "pxweb_explorer")
  x$pxobjs[[pxe_position_path(x)]]$pxobj
}

#' @rdname pxe_pxobj_at_position
#' @keywords internal
`pxe_pxobj_at_position<-` <- function(x, value) {
  checkmate::assert_class(x, "pxweb_explorer")
  checkmate::assert_true(inherits(value, "pxweb_levels") | inherits(value, "pxweb_metadata"))
  x$pxobjs[[pxe_position_path(x)]]$pxobj <- value
  if (inherits(value, "pxweb_metadata")) {
    x$metadata$position[1] <- value$variables[[1]]$code
  }
  assert_pxweb_explorer(x)
  x
}

#' Is the current position a metadata object?
#' @param x a \code{pxweb_explorer} object to check.
#' @keywords internal
pxe_position_is_metadata <- function(x) {
  inherits(pxe_pxobj_at_position(x), "pxweb_metadata")
}

#' Is the current position a full query (i.e. choices for all metadata variables)?
#' @param x a \code{pxweb_explorer} object to check.
#' @keywords internal
pxe_position_is_full_query <- function(x) {
  if (!pxe_position_is_metadata(x)) {
    return(FALSE)
  }
  md_ch <- length(pxe_metadata_choices(x))
  md_pos <- length(pxe_metadata_path(x, as_vector = TRUE))
  md_vnm <- length(pxe_metadata_variable_names(x))

  md_vnm == md_ch && md_pos == md_ch
}

#' Is the current position an api_catalogue position?
#' @param x a \code{pxweb_explorer} object to check.
#' @keywords internal
pxe_position_is_api_catalogue <- function(x) {
  is.null(x$pxweb)
}

#' How many choices has the current position?
#' @param x a \code{pxweb_explorer} object to check.
#' @keywords internal
pxe_position_choice_size <- function(x) {
  if (pxe_position_is_metadata(x)) {
    cs <- pxe_position_print_size(x)
  } else {
    obj <- pxe_pxobj_at_position(x)
    choices_df <- pxweb_levels_choices_df(obj)
    cs <- max(choices_df$choice_idx, na.rm = TRUE)
  }
  cs
}

#' @rdname pxe_position_choice_size
#' @keywords internal
pxe_position_print_size <- function(x) {
  if (pxe_position_is_metadata(x)) {
    md <- pxe_pxobj_at_position(x)
    md <- pxweb_metadata_dim(md)
    mdpos <- length(pxe_metadata_path(x, as_vector = TRUE))
    cs <- unname(md[mdpos])
  } else {
    cs <- length(pxe_pxobj_at_position(x))
  }
  cs
}

#' Can the variable at the current position be eliminated?
#' @param x a \code{pxweb_explorer} object to check.
#' @keywords internal
pxe_position_variable_can_be_eliminated <- function(x) {
  res <- FALSE
  if (pxe_position_is_metadata(x)) {
    md <- pxe_pxobj_at_position(x)
    mdpos <- length(pxe_metadata_path(x, as_vector = TRUE))
    res <- md$variables[[mdpos]]$elimination
  }
  res
}

#' Are multiple choices allowed?
#' @param x a \code{pxweb_explorer} object to check.
#' @keywords internal
pxe_position_multiple_choice_allowed <- function(x) {
  pxe_position_is_metadata(x)
}

#' Taken from \code{trimws} for reasons of compatibility with previous R versios.
#' @keywords internal
#' @seealso trimws
#' @param x a string to trim.
#' @param which how to trim the string.
str_trim <- function(x, which = c("both", "left", "right")) {
  which <- match.arg(which)
  mysub <- function(re, x) sub(re, "", x, perl = TRUE)
  if (which == "left") {
    return(mysub("^[ \t\r\n]+", x))
  }
  if (which == "right") {
    return(mysub("[ \t\r\n]+$", x))
  }
  mysub("[ \t\r\n]+$", mysub("^[ \t\r\n]+", x))
}

#' Get the meta data variable names from a \code{pxweb_explorer} object.
#' @param x a \code{pxweb_explorer} object
#' @keywords internal
pxe_metadata_variable_names <- function(x) {
  checkmate::assert_true(pxe_position_is_metadata(x))
  md <- pxe_pxobj_at_position(x)
  names(pxweb_metadata_dim(md))
}


#' Get the url to a table
#' @param x a \code{pxweb_explorer} object
#' @keywords internal
pxe_data_url <- function(x) {
  checkmate::assert_true(pxe_position_is_metadata(x))
  pxe_position_path(x, include_rootpath = TRUE, as_vector = FALSE)
}



#' Ask to download and download data
#'
#' @param pxe a \code{pxweb_explorer} object with full query
#' @param test_input a test input for testing the function.
#' Since two question, supply a vector of length two.
#' @keywords internal
pxe_interactive_get_data <- function(pxe, test_input = NULL) {
  checkmate::assert_true(pxe_position_is_full_query(pxe))
  checkmate::assert_character(test_input, null.ok = TRUE, min.len = 1)

  test_idx <- 1
  print_code <- pxe_input(
    allowed_input = pxe_allowed_input(c("y", "n")),
    "Do you want to print code to query and download data?\n",
    test_input = test_input[test_idx]
  ) == "y"
  if (print_code) {
    test_idx <- test_idx + 1
    print_json <- pxe_input(
      allowed_input = pxe_allowed_input(c("y", "n")),
      "Do you want to print query in json format (otherwise query is printed as an R list)?\n",
      test_input = test_input[test_idx]
    ) == "y"
  }
  test_idx <- test_idx + 1
  download <- pxe_input(
    allowed_input = pxe_allowed_input(c("y", "n")),
    title = "Do you want to download the data?\n",
    test_input = test_input[test_idx]
  ) == "y"

  checkmate::assert_character(test_input, null.ok = TRUE, min.len = 2)
  return_df <- FALSE
  print_citation <- FALSE
  if (download) {
    test_idx <- test_idx + 1
    return_df <- pxe_input(
      allowed_input = pxe_allowed_input(c("y", "n")),
      "Do you want to return a the data as a data.frame?\n",
      test_input = test_input[test_idx]
    ) == "y"

    test_idx <- test_idx + 1
    print_citation <- pxe_input(
      allowed_input = pxe_allowed_input(c("y", "n")),
      "Do you want to print citation for the data?\n",
      test_input = test_input[test_idx]
    ) == "y"
  }

  if (download) {
    dat <- pxweb_get(url = pxe_data_url(pxe), query = pxweb_query(pxe))
  } else {
    dat <- NULL
  }

  if (print_code) {
    if (print_json) {
      pxe_print_download_code(pxe, "json")
    } else {
      pxe_print_download_code(pxe, "r")
    }
  }
  if (print_citation) {
    cat("############# CITATION #############")
    pxweb_cite(dat)
    cat("############# CITATION #############\n")
  }
  if (return_df) {
    dat <- as.data.frame(dat)
  }
  dat
}

#' Print code to download query
#' @param pxe a \code{pxweb_query} object.
#' @param as \code{json} or \code{r}.
#' @keywords internal
pxe_print_download_code <- function(pxe, as) {
  checkmate::assert_class(pxe, "pxweb_explorer")
  checkmate::assert_choice(as, choices = c("json", "r"))
  q <- pxweb_query(pxe)
  if (as == "json") {
    q_path <- "\"[path to jsonfile]\""
    cat("######## STORE AS JSON FILE ########\n")
    print(pxweb_query_as_json(q, pretty = TRUE))
    cat("######## STORE AS JSON FILE ########\n\n")
  }
  if (as == "r") {
    cat("# PXWEB query \n")
    q_path <- "pxweb_query_list"
    pxweb_query_as_rcode(q)
    cat("\n")
  }
  cat("# Download data \n",
    "px_data <- \n",
    "  pxweb_get(url = \"", pxe_data_url(pxe), "\",\n",
    "            query = ", q_path, ")\n\n",
    sep = ""
  )
  cat("# Convert to data.frame \n",
    "px_data_frame <- as.data.frame(px_data, column.name.type = \"text\", variable.value.type = \"text\")\n\n",
    sep = ""
  )

  cat("# Get pxweb data comments \n",
    "px_data_comments <- pxweb_data_comments(px_data)\n",
    "px_data_comments_df <- as.data.frame(px_data_comments)\n\n",
    sep = ""
  )

  cat("# Cite the data as \n",
    "pxweb_cite(px_data)\n\n",
    sep = ""
  )

  return(invisible(NULL))
}
