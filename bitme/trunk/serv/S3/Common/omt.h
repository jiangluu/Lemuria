/*
 * Copyright (c) 2013, BohuTANG <overred.shuttler at gmail dot com>
 * All rights reserved.
 * Code is licensed with GPL. See COPYING.GPL file.
 *
 */

#ifndef _OMT_H_
#define _OMT_H_

#include <stdint.h>

struct slice {
	int size;
	char *data;
	int size2;
	char *val;
};

struct omt_val {
	void *val;
};

struct omt_subtree {
	uint32_t idx;
};

struct omt_node {
	int weight;
	uint32_t nidx;
	struct slice *value;
	struct omt_subtree left;
	struct omt_subtree right;
} __attribute__((packed));

struct omt_tree {
	unsigned int capacity;
	unsigned int free_idx;
	struct omt_node *nodes;
	struct omt_subtree root_subtree;

	uint64_t status_rebalance_nums;
};


struct omt_tree *omt_new();

int omt_insert(struct omt_tree *tree, struct slice *val);

int omt_find_order(struct omt_tree *tree, struct slice *val, uint32_t *order);

void omt_free(struct omt_tree *tree);


// easy API below.  Where key must be a string

void slice_init(struct slice *s);

int omt_put(struct omt_tree *tree,char *key,int valuelen,char *value);

int omt_get(struct omt_tree *tree,char *key,struct slice **v);




#endif
