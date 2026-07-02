##############################################################################
################################ makefile ####################################
##############################################################################
#                                                                            #
#   makefile of TemplateBlock                                                #
#                                                                            #
#   Note that $(SMS++INC) is assumed to include any -I directive             #
#   corresponding to external libraries needed by SMS++, at least to the     #
#   extent in which they are needed by the parts of SMS++ used by            #
#   TemplateBlock.                                                           #
#                                                                            #
#   Input:  $(CC)        = compiler command                                  #
#           $(SW)        = compiler options                                  #
#           $(SMS++INC)  = the -I$( core SMS++ directory )                   #
#           $(SMS++OBJ)  = the libSMS++ library itself                       #
#           $(TmpBkSDR)  = the directory where the source is                 #
#                                                                            #
#   Output: $(TmpBkOBJ)  = the final object(s) / library                     #
#           $(TmpBkH)    = the .h files to include                           #
#           $(TmpBkINC)  = the -I$( source directory )                       #
#                                                                            #
#                              Template Author                               #
#                         Dipartimento di Informatica                        #
#                             Universita' di Pisa                            #
#                                                                            #
##############################################################################

# macros to be exported - - - - - - - - - - - - - - - - - - - - - - - - - - -

TmpBkOBJ = $(TmpBkSDR)/obj/TemplateBlock.o

TmpBkINC = -I$(TmpBkSDR)/include

TmpBkH   = $(TmpBkSDR)/include/TemplateBlock.h

# clean - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

clean::
	rm -f $(TmpBkOBJ) $(TmpBkSDR)/*~

# dependencies: every .o from its .cpp + every recursively included .h- - - -

$(TmpBkSDR)/obj/TemplateBlock.o: $(TmpBkSDR)/src/TemplateBlock.cpp \
	$(TmpBkSDR)/include/TemplateBlock.h $(SMS++H) $(SMS++OBJ)
	$(CC) -c $(TmpBkSDR)/src/TemplateBlock.cpp -o $@ \
	$(TmpBkINC) $(SMS++INC) $(SW)

########################## End of makefile ###################################
