#!/usr/bin/python

# from https://bitbucket.org/kent37/python-tutor-samples/src/f657aeba5328/BinPacking.py
#
# Original author: Kent S Johnson <kent@kentsjohnson.com>
# Website: http://kentsjohnson.com/

# Adapted by Frank Scheiner 2014-2016

''' Partition a list into sublists whose sums don't exceed a maximum
     using a First Fit Decreasing algorithm. See
     http://www.ams.org/new-in-math/cover/bins1.html
     for a simple description of the method.
'''

# TODO:
# * [ ] Describe functioning and usage of this tool!
# * [ ] Remove garbage und unneccessary comments
# * [ ] Move functions and includes to respective blocks

# version 0.3.0

################################################################################
# INCLUDES
################################################################################
from __future__ import print_function

import sys
import math


################################################################################
# FUNCTIONS
################################################################################
class SizeBin(object):
     ''' Container for items that keeps a running sum '''
     def __init__(self):
         self.items = []
         self.sum = 0

     def append(self, item):
         self.items.append(item)
         self.sum += item

     def __str__(self):
         ''' Printable representation '''
         return 'Bin(sum=%d, items=%s)' % (self.sum, str(self.items))


class LineBin(object):
     ''' Container for transfer list lines '''
     def __init__(self):
         self.items = []

     def append(self, item):
         self.items.append(item)

     def __str__(self):
         ''' Printable representation '''
         return str(self.items)


def pack(values, maxValue):
     print(time.time(), 'START: Sorting list', file=sys.stderr)
     # sorts correctly using the size (first array element in each line, which
     # is the file size; second array element is the complete transfer list
     # line) as determinator
     values = sorted(values, reverse=True)
     print(time.time(), 'END: Sorting list', file=sys.stderr)

     sizeBins = []
     lineBins = []

     for item in values:
         # Try to fit item into a bin
         # http://stackoverflow.com/questions/603641/using-for-else-in-python-generators
         # http://stackoverflow.com/questions/1663807/how-can-i-iterate-through-two-lists-in-parallel-in-python
         for sizeBin, lineBin in zip(sizeBins, lineBins):
             if sizeBin.sum + item[0] <= maxValue:
                 #print 'Adding', item, 'to', bin
                 sizeBin.append(item[0])
                 lineBin.append(item[1])
                 break
         else:
             # item didn't fit into any bin, start a new bin
             #print 'Making new bin for', item
             sizeBin = SizeBin()
             lineBin = []
             sizeBin.append(item[0])
             lineBin.append(item[1])
             sizeBins.append(sizeBin)
             lineBins.append(lineBin)

     return lineBins
     #return sizeBins


def getSize(line):
    #                   123456
    indexA = line.find(' size=')
    indexB = line[indexA:].find(';')

    # increase index of start by 6 chars, so first returned char is first digit
    # of size.
    size = line[indexA + 6:indexA + indexB]

    return int(size)


# http://stackoverflow.com/questions/3844801/check-if-all-elements-in-a-list-are-identical
def checkEqualIvo(lst):
    return not lst or lst.count(lst[0]) == len(lst)


################################################################################
# MAIN
################################################################################
if __name__ == '__main__':
    import random
    import time

    def packAndShow(aList, maxValue):
        ''' Pack a list into bins and show the result '''
        #print 'List with sum', sum(aList), 'requires at least', (sum(aList)+maxValue-1)/maxValue, 'bins'
        bins1 = pack(aList, maxValue)
        #print 'Solution using', len(bins1), 'bins:'
        for bin1 in bins1:
            print(bin1)


    #aList = [10,9,8,7,6,5,4,3,2,1]
    #packAndShow(aList, 11)

    #aList = [5, 4, 4, 3, 2, 2]
    #packAndShow(aList, 10)

    #aList = [ random.randint(1, 11) for i in range(100) ]
    combinedList = []
    # http://stackoverflow.com/questions/13890935/timestamp-python
    print(time.time(), 'START: Read transfer list file', file=sys.stderr)
    for line in open(sys.argv[1]):
        if not line.startswith("#"):
            # get size from each line
            size = getSize(line)
            combinedList.append([size, line])
    print(time.time(), 'END: Read transfer list file', file=sys.stderr)

    # arbitrary number of paths possible
    #packAndShow(combinedList, max(combinedList)[0])

    #print combinedList

    print(time.time(), 'START: Bin packing', file=sys.stderr)
    lineBins = pack(combinedList, max(combinedList)[0])
    print(time.time(), 'END: Bin packing', file=sys.stderr)

    #for lineBin in lineBins:
    #    print lineBin

    # http://stackoverflow.com/questions/4130027/python-count-elements-in-list
    numberOfLineBins = len(lineBins)

    #print "Number of line bins: ", numberOfLineBins

    #proportions = [ 5, 10, 1 ]     
    proportions = []
    print(time.time(), 'START: Read bandwidth proportions file', file=sys.stderr)
    for line in open(sys.argv[2]):
        proportions.append(int(line))
    print(time.time(), 'END: Read bandwidth proportions file', file=sys.stderr)

    sumOfProportions = sum(proportions)
    numberOfProportions = len(proportions)
    # http://stackoverflow.com/questions/3989016/how-to-find-positions-of-the-list-maximum
    indexOfMaxProportion = proportions.index(max(proportions))

    # http://stackoverflow.com/questions/17141979/round-a-floating-point-number-down-to-the-nearest-integer
    numberOfListsPerProportion = math.floor(numberOfLineBins / sumOfProportions)

    transferListFiles = []

    # If numberOfListsPerProportion gets smaller than 1, we could distribute
    # lists in a round-robin fashion.
    if (numberOfListsPerProportion < 1) or (checkEqualIvo(proportions) == True):
    #if (numberOfListsPerProportion < 1):

        print(time.time(), 'START: Building lists', file=sys.stderr)
        proportionIndex = 0

        transferLists = []

        # The following is needed because witout it python gives an "IndexError:
        # list index out of range" error later when trying to access non
        # existing list elements.
        for proportion in proportions:
            transferLists.append("")
        # Possible other ways (maybe!):
        # http://stackoverflow.com/questions/521674/initializing-a-list-to-a-known-number-of-elements-in-python

        # create transfer lists in memory
        for lineBin in lineBins:

            # http://www.decalage.info/en/python/print_list
            transferLists[proportionIndex] += ''.join(lineBin)

            if proportionIndex == numberOfProportions -1:
                proportionIndex = 0
            else:
                proportionIndex += 1

        proportionIndex = 0

        # write out transfer lists
        while proportionIndex < numberOfProportions:

            transferListfileName = str(proportionIndex) + '.list'

            # http://stackoverflow.com/questions/6159900/correct-way-to-write-line-to-file-in-python
            file = open(transferListfileName, 'w')
            file.write(transferLists[proportionIndex])
            file.close()

            transferListFiles.append(transferListfileName)

            proportionIndex += 1

        print(time.time(), 'END: Building lists' , file=sys.stderr)

    #print "Number of lists per proportion: ", numberOfListsPerProportion

    else:
        print(time.time(), 'START: Building main lists', file=sys.stderr)

        counter = 0
        start = 0
        end = 0
        for proportion in proportions:

            end += int(numberOfListsPerProportion * proportion)

     	    #print start, end

            currentList = ""
     	    #              from start (including) to end (not including!)

     	    print(time.time(), 'START: Joining contents of selected bins', file=sys.stderr)
     	    for lineBin in lineBins[start:end]:
     	        currentList += ''.join(lineBin)
     	    print(time.time(), 'END: Joining contents of selected bins', file=sys.stderr)

            transferListfileName = str(counter) + '.list'

            file = open(transferListfileName, 'w')
            file.write(currentList)     	
            file.close()

            transferListFiles.append(transferListfileName)

            start = end
            counter += 1
        
        print(time.time(), 'END: Building main lists', file=sys.stderr)

        print(time.time(), 'START: Adding remaining list', file=sys.stderr)

        # add remaining lists/bins to list for the max proportion element (if all
        # proportions are equal, the first wins)
        remainingList = ""

        #print start, numberOfLineBins

        print(time.time(), 'START: Joining contents of remaining bins', file=sys.stderr)
        for lineBin in lineBins[start:]:
     	     remainingList += ''.join(lineBin)
        print(time.time(), 'START: Joining contents of remaining bins', file=sys.stderr)

        file = open(str(indexOfMaxProportion) + '.list', 'a')
	# http://stackoverflow.com/questions/3611760/scoping-in-python-for-loops
        file.write(remainingList)
     	file.close()

        print(time.time(), 'END: Adding remaining list', file=sys.stderr)

    print(' '.join(transferListFiles), file=sys.stdout)

    # http://stackoverflow.com/questions/73663/terminating-a-python-script
    sys.exit()

    # arbitrary number of paths possible
    #packAndShow(combinedList, max(combinedList)[0])

    # optimization for two paths
    #binSize = float(sys.argv[2]) * sum(aList)
    #packAndShow(aList, binSize)

