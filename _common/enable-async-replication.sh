#!/bin/bash
cat << EOF >> /etc/irods/core.re
# These rules have been adapted from the irods-ruleset-uu repo at
# https://github.com/utrechtuniversity/irods-ruleset-uu

PRIMARYRESOURCES = list("demoResc");
REPLICATIONRESOURCE = "consumerResource";

chopPath(*path, *parent, *baseName) {
        if (*path like regex "^/[^/]*$") {
                # *path is "/" or a top level directory.
                *baseName = if strlen(*path) > 1 then substr(*path, 1, strlen(*path)) else "/";
                *parent   = "/";
        } else {
                chop(*path, *parent, *baseName, "/", false);
        }
}

chop(*string, *head, *tail, *splitChar, *leftToRight) {
        if (*string like "**splitChar*") {
                if (*leftToRight) {
                        *tail =  triml(*string, *splitChar);
                        *head = substr(*string, 0, strlen(*string) - strlen(*tail) - 1);
                } else {
                        *head =  trimr(*string, *splitChar);
                        *tail = substr(*string, strlen(*head) + 1, strlen(*string));
                }
        } else {
                # No *splitChar in *string.
                *head = if *leftToRight then ""      else *string;
                *tail = if *leftToRight then *string else "";
        }
}

inlist(*val, *lst) = if size(*lst) == 0  then false else headinlist(*val, *lst)

headinlist(*val, *lst) = if hd(*lst) == *val then true else inlist(*val, tl(*lst))

replicateAsynchronously(*object, *sourceResource, *targetResource) {
                 writeLine("serverLog", "Async Replication called.");
        delay("<PLUSET>1s</PLUSET><EF>1m DOUBLE UNTIL SUCCESS OR 10 TIMES</EF>") {
                # Find object to replicate.
                chopPath(*object, *parent, *basename);
                *objectId = 0;
                *found = false;

                foreach(*row in SELECT DATA_ID, DATA_MODIFY_TIME, DATA_OWNER_NAME, DATA_SIZE, COLL_ID, DATA_RESC_HIER
                        WHERE DATA_NAME      = *basename
                        AND   COLL_NAME      = *parent
                        AND   DATA_RESC_HIER like '*sourceResource%'
                       ) {
                        if (!*found) {
                                *found = true;
                                break;
                        }
                }

                # Skip replication if object does not exists (any more).
                if (!*found) {
                        writeLine("serverLog", "replicateAsynchronously: DataObject *parent : *basename was not found on *sourceResource.");
                        succeed;
                }

                # Replicate object to target resource.
                *options = "rescName=*sourceResource++++destRescName=*targetResource";
                msiDataObjRepl(*object, *options, *status);
        }
}

pep_resource_modified_post(*instanceName, *context, *out) {
        on(inlist(*instanceName, PRIMARYRESOURCES)) {
                replicateAsynchronously(*context.logical_path, *instanceName, REPLICATIONRESOURCE);
   }
}
EOF
