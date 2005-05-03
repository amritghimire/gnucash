/********************************************************************\
 * gncTaxTable.h -- the Gnucash Tax Table interface                 *
 *                                                                  *
 * This program is free software; you can redistribute it and/or    *
 * modify it under the terms of the GNU General Public License as   *
 * published by the Free Software Foundation; either version 2 of   *
 * the License, or (at your option) any later version.              *
 *                                                                  *
 * This program is distributed in the hope that it will be useful,  *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of   *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    *
 * GNU General Public License for more details.                     *
 *                                                                  *
 * You should have received a copy of the GNU General Public License*
 * along with this program; if not, contact:                        *
 *                                                                  *
 * Free Software Foundation           Voice:  +1-617-542-5942       *
 * 59 Temple Place - Suite 330        Fax:    +1-617-542-2652       *
 * Boston, MA  02111-1307,  USA       gnu@gnu.org                   *
 *                                                                  *
\********************************************************************/
/** @addtogroup Business
    @{ */
/** @addtogroup TaxTable
    @{ */
/** @file gncTaxTable.h
    @brief Tax Table programming interface
    @author Copyright (C) 2002 Derek Atkins <warlord@MIT.EDU>
*/

#ifndef GNC_TAXTABLE_H_
#define GNC_TAXTABLE_H_

/** @struct GncTaxTable

modtime is the internal date of the last modtime\n
See src/doc/business.txt for an explanation of the following\n
Code that handles refcount, parent, child, invisible and children 
is *identical* to that in ::GncBillTerm

@param	QofInstance     inst;
@param 	char *          name;
@param 	GList *         entries;
@param 	Timespec        modtime;	
@param 	gint64          refcount;
@param 	GncTaxTable *   parent; if non-null, we are an immutable child 
@param 	GncTaxTable *   child;  if non-null, we have not changed 
@param 	gboolean        invisible;
@param 	GList *         children; list of children for disconnection 
*/
typedef struct _gncTaxTable GncTaxTable;

/** @struct GncTaxTableEntry

@param	GncTaxTable *   table;
@param  Account *       account;
@param	GncAmountType   type;
@param	gnc_numeric     amount;
};

*/
typedef struct _gncTaxTableEntry GncTaxTableEntry;

typedef struct _gncAccountValue GncAccountValue;

#include "Account.h"
#include "gnc-date.h"
#include "gnc-numeric.h"

#include "qofbook.h"
#include "qofinstance.h"
#include "gncBusiness.h"

#define GNC_ID_TAXTABLE       "gncTaxTable"
#define GNC_IS_TAXTABLE(obj)  (QOF_CHECK_TYPE((obj), GNC_ID_TAXTABLE))
#define GNC_TAXTABLE(obj)     (QOF_CHECK_CAST((obj), GNC_ID_TAXTABLE, GncTaxTable))

/**
 * How to interpret the amount.
 * You can interpret it as a VALUE or a PERCENT.
 */
typedef enum {
  GNC_AMT_TYPE_VALUE = 1, 	/**< tax is a number */
  GNC_AMT_TYPE_PERCENT		/**< tax is a percentage */
} GncAmountType;

/** How to interpret the TaxIncluded */
typedef enum {
  GNC_TAXINCLUDED_YES = 1,  /**< tax is included */
  GNC_TAXINCLUDED_NO,		/**< tax is not included */
  GNC_TAXINCLUDED_USEGLOBAL, /**< use the global setting */
} GncTaxIncluded;

const char * gncAmountTypeToString (GncAmountType type);
gboolean gncAmountStringToType (const char *str, GncAmountType *type);

const char * gncTaxIncludedTypeToString (GncTaxIncluded type);
gboolean gncTaxIncludedStringToType (const char *str, GncTaxIncluded *type);

/** @name Create/Destroy Functions 
 @{ */
GncTaxTable * gncTaxTableCreate (QofBook *book);
void gncTaxTableDestroy (GncTaxTable *table);
GncTaxTableEntry * gncTaxTableEntryCreate (void);
void gncTaxTableEntryDestroy (GncTaxTableEntry *entry);
/** @} */
/** \name Set Functions 
@{
*/
void gncTaxTableSetName (GncTaxTable *table, const char *name);
void gncTaxTableIncRef (GncTaxTable *table);
void gncTaxTableDecRef (GncTaxTable *table);

void gncTaxTableEntrySetAccount (GncTaxTableEntry *entry, Account *account);
void gncTaxTableEntrySetType (GncTaxTableEntry *entry, GncAmountType type);
void gncTaxTableEntrySetAmount (GncTaxTableEntry *entry, gnc_numeric amount);
/** @} */
void gncTaxTableAddEntry (GncTaxTable *table, GncTaxTableEntry *entry);
void gncTaxTableRemoveEntry (GncTaxTable *table, GncTaxTableEntry *entry);

void gncTaxTableChanged (GncTaxTable *table);
void gncTaxTableBeginEdit (GncTaxTable *table);
void gncTaxTableCommitEdit (GncTaxTable *table);

/** @name Get Functions 
 @{ */

/** Return a pointer to the instance gncTaxTable that is identified
 *  by the guid, and is residing in the book. Returns NULL if the 
 *  instance can't be found.
 *  Equivalent function prototype is
 *  GncTaxTable * gncTaxTableLookup (QofBook *book, const GUID *guid);
 */
#define gncTaxTableLookup(book,guid)    \
       QOF_BOOK_LOOKUP_ENTITY((book),(guid),GNC_ID_TAXTABLE, GncTaxTable)

GncTaxTable *gncTaxTableLookupByName (QofBook *book, const char *name);

GList * gncTaxTableGetTables (QofBook *book);

const char *gncTaxTableGetName (GncTaxTable *table);
GncTaxTable *gncTaxTableGetParent (GncTaxTable *table);
GncTaxTable *gncTaxTableReturnChild (GncTaxTable *table, gboolean make_new);
#define gncTaxTableGetChild(t) gncTaxTableReturnChild((t),FALSE)
GList *gncTaxTableGetEntries (GncTaxTable *table);
gint64 gncTaxTableGetRefcount (GncTaxTable *table);
Timespec gncTaxTableLastModified (GncTaxTable *table);

Account * gncTaxTableEntryGetAccount (GncTaxTableEntry *entry);
GncAmountType gncTaxTableEntryGetType (GncTaxTableEntry *entry);
gnc_numeric gncTaxTableEntryGetAmount (GncTaxTableEntry *entry);
/** @} */

int gncTaxTableCompare (GncTaxTable *a, GncTaxTable *b);
int gncTaxTableEntryCompare (GncTaxTableEntry *a, GncTaxTableEntry *b);

/************************************************/

struct _gncAccountValue {
  Account *	account;
  gnc_numeric	value;
};

/**
 * This will add value to the account-value for acc, creating a new
 * list object if necessary
 */
GList *gncAccountValueAdd (GList *list, Account *acc, gnc_numeric value);

/** Merge l2 into l1.  l2 is not touched. */
GList *gncAccountValueAddList (GList *l1, GList *l2);

/** return the total for this list */
gnc_numeric gncAccountValueTotal (GList *list);

/** Destroy a list of accountvalues */
void gncAccountValueDestroy (GList *list);

/** QOF parameter definitions */
#define GNC_TT_NAME "tax table name"
#define GNC_TT_REFCOUNT "reference count"

/** @deprecated routine */
#define gncTaxTableGetGUID(x) qof_instance_get_guid(QOF_INSTANCE(x))
#define gncTaxTableRetGUID(x) (x ? *(qof_instance_get_guid(QOF_INSTANCE(x))) : *(guid_null()))
#define gncTaxTableLookupDirect(G,B) gncTaxTableLookup((B), &(G))

#endif /* GNC_TAXTABLE_H_ */
/** @} */
/** @} */
