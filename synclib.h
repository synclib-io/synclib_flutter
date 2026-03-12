/**
 * SyncLib - Cross-platform SQLite sync library
 *
 * Provides SQLite operations with automatic change tracking for syncing
 * over network connections (e.g., WebSocket).
 */

#ifndef SYNCLIB_H
#define SYNCLIB_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return codes */
#define SYNCLIB_OK 0
#define SYNCLIB_ERROR -1
#define SYNCLIB_NO_MORE_CHANGES 1

/* Operation types */
typedef enum {
    SYNCLIB_OP_INSERT = 1,
    SYNCLIB_OP_UPDATE = 2,
    SYNCLIB_OP_DELETE = 3
} synclib_operation_t;

/* Opaque handle to database connection */
typedef struct synclib_db synclib_db_t;

/* Change record structure */
typedef struct {
    int64_t seqnum;            /* Sequence number (monotonically increasing) */
    const char* table_name;
    const char* row_id;
    synclib_operation_t operation;
    const char* data;          /* JSON-encoded row data, NULL for DELETE */
} synclib_change_t;

/**
 * Initialize and open database connection
 *
 * @param db_path Path to SQLite database file
 * @param db Output parameter for database handle
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_open(const char* db_path, synclib_db_t** db);

/**
 * Close database connection and free resources
 *
 * @param db Database handle
 */
void synclib_close(synclib_db_t* db);

/**
 * Execute a write operation (INSERT, UPDATE, DELETE)
 * Automatically tracks the change for syncing
 *
 * @param db Database handle
 * @param table_name Name of table being modified
 * @param row_id Primary key of the row (as string)
 * @param operation Type of operation
 * @param sql SQL statement to execute
 * @param data JSON-encoded row data (NULL for DELETE)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_write(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    synclib_operation_t operation,
    const char* sql,
    const char* data
);

/**
 * Execute a write operation with parameterized query (INSERT, UPDATE, DELETE)
 * Automatically tracks the change for syncing
 * Supports ? placeholders in SQL for safe parameter binding
 *
 * @param db Database handle
 * @param table_name Name of table being modified
 * @param row_id Primary key of the row (as string)
 * @param operation Type of operation
 * @param sql SQL statement with ? placeholders
 * @param params Array of string parameters (NULL-terminated strings)
 * @param param_count Number of parameters in the array
 * @param data JSON-encoded row data (NULL for DELETE)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 *
 * Example:
 *   const char* params[] = {"value1", "value2"};
 *   synclib_write_params(db, "users", "123", SYNCLIB_OP_UPDATE,
 *                        "UPDATE users SET name = ?, email = ? WHERE id = ?",
 *                        params, 2, data);
 */
int synclib_write_params(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    synclib_operation_t operation,
    const char* sql,
    const char** params,
    int param_count,
    const char* data
);

/**
 * Write with typed parameterized query (supports TEXT and BLOB parameters)
 * Useful for storing JSONB binary data directly
 *
 * @param db Database handle
 * @param table_name Name of table being modified
 * @param row_id Primary key of the row (as string)
 * @param operation Type of operation
 * @param sql SQL statement with ? placeholders
 * @param text_params Array of text parameters (NULL-terminated strings)
 * @param blob_params Array of blob data pointers
 * @param blob_sizes Array of blob sizes in bytes
 * @param param_types Array indicating parameter types (0=NULL, 1=TEXT, 2=BLOB)
 * @param param_count Number of parameters
 * @param data JSON-encoded row data for tracking (optional, can be NULL)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_write_params_typed(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    synclib_operation_t operation,
    const char* sql,
    const char** text_params,
    const unsigned char** blob_params,
    const int* blob_sizes,
    const int* param_types,
    int param_count,
    const char* data
);

/**
 * Execute a SQL statement without tracking (for schema changes, setup, etc.)
 * Use this for DDL operations like CREATE TABLE, ALTER TABLE, CREATE INDEX
 *
 * @param db Database handle
 * @param sql SQL statement to execute
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_exec(synclib_db_t* db, const char* sql);

/**
 * Get current schema version from metadata table
 *
 * @param db Database handle
 * @param version Output parameter for version number
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_get_schema_version(synclib_db_t* db, int* version);

/**
 * Set schema version in metadata table
 *
 * @param db Database handle
 * @param version Version number to set
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_set_schema_version(synclib_db_t* db, int version);

/**
 * Execute a read-only query (simple callback with string values only)
 * Note: BLOB columns cannot be read with this function - use synclib_read_raw instead
 *
 * @param db Database handle
 * @param sql SQL SELECT statement
 * @param callback Function called for each result row
 * @param user_data User data passed to callback
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 *
 * Callback signature: int callback(void* user_data, int argc, char** argv, char** col_names)
 * Return 0 from callback to continue, non-zero to stop iteration
 */
int synclib_read(
    synclib_db_t* db,
    const char* sql,
    int (*callback)(void*, int, char**, char**),
    void* user_data
);

/**
 * Row data structure for synclib_read_raw callback
 */
typedef struct {
    int type;              /* SQLITE_INTEGER, SQLITE_FLOAT, SQLITE_TEXT, SQLITE_BLOB, or SQLITE_NULL */
    const char* text_value; /* For TEXT type (NULL-terminated) */
    const void* blob_value; /* For BLOB type */
    int blob_size;         /* Size of BLOB in bytes */
    int64_t int_value;     /* For INTEGER type */
    double float_value;    /* For FLOAT type */
} synclib_column_value_t;

/**
 * Execute a read-only query with full type support (including BLOBs)
 *
 * @param db Database handle
 * @param sql SQL SELECT statement
 * @param callback Function called for each result row
 * @param user_data User data passed to callback
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 *
 * Callback signature: int callback(void* user_data, int col_count,
 *                                   const char** col_names, const synclib_column_value_t* values)
 * Return 0 from callback to continue, non-zero to stop iteration
 */
int synclib_read_raw(
    synclib_db_t* db,
    const char* sql,
    int (*callback)(void*, int, const char**, const synclib_column_value_t*),
    void* user_data
);

/**
 * Get pending changes that need to be synced
 *
 * @param db Database handle
 * @param changes Output array of changes (caller must free with synclib_free_changes)
 * @param count Output parameter for number of changes
 * @param limit Maximum number of changes to retrieve
 * @return SYNCLIB_OK on success, SYNCLIB_NO_MORE_CHANGES if empty, SYNCLIB_ERROR on failure
 */
int synclib_get_pending_changes(
    synclib_db_t* db,
    synclib_change_t** changes,
    int* count,
    int limit
);

/**
 * Mark changes as synced (removes them from pending changes)
 *
 * @param db Database handle
 * @param seqnum Sequence number up to and including which to mark as synced
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_mark_synced(synclib_db_t* db, int64_t seqnum);

/**
 * Delete a specific change by sequence number
 * Use this for precise cleanup after server acknowledgment
 *
 * @param db Database handle
 * @param seqnum Exact sequence number of the change to delete
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_delete_change(synclib_db_t* db, int64_t seqnum);

/**
 * Apply a remote change from another client/server
 * Does NOT add to pending changes (avoids sync loop)
 *
 * @param db Database handle
 * @param table_name Name of table being modified
 * @param row_id Primary key of the row (as string)
 * @param operation Type of operation
 * @param sql SQL statement to execute (INSERT/UPDATE/DELETE)
 * @param data JSON-encoded row data for tracking (optional, can be NULL)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_apply_remote(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    synclib_operation_t operation,
    const char* sql,
    const char* data
);

/**
 * Apply a remote change with parameterized query (for JSONB support)
 * Does NOT add to pending changes (avoids sync loop)
 * Supports ? placeholders in SQL for safe parameter binding
 *
 * @param db Database handle
 * @param table_name Name of table being modified
 * @param row_id Primary key of the row (as string)
 * @param operation Type of operation
 * @param sql SQL statement with ? placeholders
 * @param params Array of string parameters (NULL-terminated strings)
 * @param param_count Number of parameters in the array
 * @param data JSON-encoded row data for tracking (optional, can be NULL)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 *
 * Example:
 *   const char* params[] = {"{\"name\":\"John\"}", "user123"};
 *   synclib_apply_remote_params(db, "users", "123", SYNCLIB_OP_UPDATE,
 *                                "UPDATE users SET document = jsonb(?) WHERE id = ?",
 *                                params, 2, NULL);
 */
int synclib_apply_remote_params(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    synclib_operation_t operation,
    const char* sql,
    const char** params,
    int param_count,
    const char* data
);

/**
 * Apply remote change with typed parameterized query (supports TEXT and BLOB)
 * Does NOT add to pending changes (avoids sync loop)
 *
 * @param db Database handle
 * @param table_name Name of table being modified
 * @param row_id Primary key of the row (as string)
 * @param operation Type of operation
 * @param sql SQL statement with ? placeholders
 * @param text_params Array of text parameters (NULL-terminated strings)
 * @param blob_params Array of blob data pointers
 * @param blob_sizes Array of blob sizes in bytes
 * @param param_types Array indicating parameter types (0=NULL, 1=TEXT, 2=BLOB)
 * @param param_count Number of parameters
 * @param data JSON-encoded row data for tracking (optional, can be NULL)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_apply_remote_params_typed(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    synclib_operation_t operation,
    const char* sql,
    const char** text_params,
    const unsigned char** blob_params,
    const int* blob_sizes,
    const int* param_types,
    int param_count,
    const char* data
);

/**
 * Begin bulk remote operation mode
 * Starts a transaction and disables change tracking for efficient bulk imports
 * Must be followed by synclib_end_bulk_remote()
 *
 * Use this for initial sync or large data transfers (thousands of rows)
 *
 * @param db Database handle
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_begin_bulk_remote(synclib_db_t* db);

/**
 * Execute a SQL statement in bulk remote mode
 * Must be called between synclib_begin_bulk_remote() and synclib_end_bulk_remote()
 *
 * @param db Database handle
 * @param sql SQL statement to execute
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_exec_bulk_remote(synclib_db_t* db, const char* sql);

/**
 * End bulk remote operation mode
 * Commits the transaction and re-enables change tracking
 *
 * @param db Database handle
 * @param rollback If non-zero, rollback instead of commit
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_end_bulk_remote(synclib_db_t* db, int rollback);

/**
 * Free changes array returned by synclib_get_pending_changes
 *
 * @param changes Array to free
 * @param count Number of changes in array
 */
void synclib_free_changes(synclib_change_t* changes, int count);

/**
 * Extract a row as JSON by querying the table schema and values
 * Useful for auto-generating JSON from table rows for syncing
 *
 * @param db Database handle
 * @param table_name Name of table
 * @param row_id Primary key value (assumes 'id' column)
 * @param json_out Output parameter for JSON string (caller must free)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_row_to_json(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    char** json_out
);

/**
 * Get last error message
 *
 * @param db Database handle
 * @return Error message string (valid until next operation)
 */
const char* synclib_get_error(synclib_db_t* db);

/* ============================================================================
 * Merkle Tree Functions
 *
 * These functions provide Merkle tree-based integrity verification for sync.
 * Block-based hashing allows efficient detection and repair of data drift.
 * ============================================================================ */

/* Default block size for Merkle tree operations */
#define SYNCLIB_DEFAULT_BLOCK_SIZE 100

/* Merkle tree info structure */
typedef struct {
    char* root_hash;    /* Hex-encoded SHA256 hash (caller must free) */
    int block_count;    /* Number of blocks in the tree */
    int row_count;      /* Total number of rows */
} synclib_merkle_info_t;

/**
 * Compute SHA256 hash of a single row (database-aware wrapper)
 *
 * Hash is computed as: SHA256(row_id || '|' || sorted_json(row_data))
 * This ensures consistent hashing across platforms.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param row_id Primary key of the row
 * @param hash_out Output: hex-encoded SHA256 hash (caller must free)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_db_row_hash(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    char** hash_out
);

/**
 * Get the sorted JSON representation of a row for debugging.
 * This is the same JSON that would be hashed for merkle verification.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param row_id Primary key of the row
 * @param json_out Output: canonical sorted JSON string (caller must free)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_db_row_json(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id,
    char** json_out
);

/**
 * Compute SHA256 hash of a block of rows (database-aware wrapper)
 *
 * Rows are ordered by 'id' column. Block hash is computed as:
 * SHA256(row_hash_1 || row_hash_2 || ... || row_hash_N)
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param block_index Zero-based block index
 * @param block_size Number of rows per block
 * @param hash_out Output: hex-encoded SHA256 hash (caller must free)
 * @param row_count_out Output: actual number of rows in this block
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_db_block_hash(
    synclib_db_t* db,
    const char* table_name,
    int block_index,
    int block_size,
    char** hash_out,
    int* row_count_out
);

/**
 * Compute Merkle root hash for a table (database-aware wrapper)
 *
 * Builds a complete Merkle tree from all rows (ordered by id) and
 * returns the root hash along with statistics.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param block_size Number of rows per block (use SYNCLIB_DEFAULT_BLOCK_SIZE)
 * @param info_out Output: Merkle tree info (caller must free root_hash)
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_db_merkle_root(
    synclib_db_t* db,
    const char* table_name,
    int block_size,
    synclib_merkle_info_t* info_out
);

/**
 * Get all block hashes for a table
 *
 * Returns an array of hex-encoded block hashes in order.
 * Useful for comparing block-by-block with server.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param block_size Number of rows per block
 * @param block_hashes_out Output: array of hex hash strings (caller must free each + array)
 * @param block_count_out Output: number of block hashes
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_merkle_block_hashes(
    synclib_db_t* db,
    const char* table_name,
    int block_size,
    char*** block_hashes_out,
    int* block_count_out
);

/**
 * Get row IDs in a specific block
 *
 * Returns the row IDs (ordered by id) that belong to a given block.
 * Useful for fetching specific block data after detecting a mismatch.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param block_index Zero-based block index
 * @param block_size Number of rows per block
 * @param row_ids_out Output: array of row ID strings (caller must free each + array)
 * @param count_out Output: number of row IDs returned
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_get_block_row_ids(
    synclib_db_t* db,
    const char* table_name,
    int block_index,
    int block_size,
    char*** row_ids_out,
    int* count_out
);

/**
 * Free a Merkle info structure
 *
 * @param info Pointer to info structure (can be NULL)
 */
void synclib_free_merkle_info(synclib_merkle_info_t* info);

/**
 * Free an array of strings (for block hashes or row IDs)
 *
 * @param strings Array of strings to free
 * @param count Number of strings in array
 */
void synclib_free_string_array(char** strings, int count);

/**
 * Recompute and store row_hash for a single row
 *
 * Call this after bulk remote writes to keep precomputed hashes current.
 * Silently skips if the table has no row_hash column.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param row_id Primary key of the row
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_update_row_hash(
    synclib_db_t* db,
    const char* table_name,
    const char* row_id
);

/**
 * Backfill row_hash for all rows in a table that have NULL row_hash.
 *
 * Idempotent: only processes rows where row_hash IS NULL.
 * Runs in a single transaction for efficiency.
 * No-op if the table has no row_hash column.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_backfill_row_hashes(
    synclib_db_t* db,
    const char* table_name
);

/**
 * Configure which columns are included in row_hash for a table.
 *
 * When set, only id + the named columns are hashed (whitelist mode).
 * This must match the server's pg_synclib_hash trigger configuration
 * for the precomputed row_hash values to be consistent.
 *
 * Persists config to _synclib_hash_config table and caches in memory.
 * If config changes, existing row_hash values are invalidated (set NULL)
 * so that backfill_row_hashes() will recompute them.
 *
 * @param db Database handle
 * @param table_name Name of the table
 * @param columns_json JSON array of column names, e.g. '["last_modified_ms"]'
 * @return SYNCLIB_OK on success, SYNCLIB_ERROR on failure
 */
int synclib_set_hash_columns(
    synclib_db_t* db,
    const char* table_name,
    const char* columns_json
);

#ifdef __cplusplus
}
#endif

#endif /* SYNCLIB_H */