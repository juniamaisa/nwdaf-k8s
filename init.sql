CREATE TABLE public."result" (
	id uuid DEFAULT gen_random_uuid (),
	"date" date NULL,
	"class" int NULL
);
	 
CREATE TABLE public.pcap_file (
	id uuid DEFAULT gen_random_uuid(),
	"timestamp" timestamp DEFAULT current_timestamp,
	"name" varchar NULL
);

CREATE TABLE public.rotulate_dataset (
	id uuid NULL DEFAULT gen_random_uuid(),
	"timestamp" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
	name varchar NULL
);

CREATE TABLE public.supervised_dataset (
	id uuid NULL DEFAULT gen_random_uuid(),
	"timestamp" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
	name varchar NULL
);

ALTER TABLE public."result" ADD pcap_file_id uuid NULL;
ALTER TABLE public."result" RENAME COLUMN "date" TO "timestamp";
ALTER TABLE public."result" ALTER COLUMN "timestamp" TYPE timestamp USING "timestamp"::timestamp;
ALTER TABLE public."result" ALTER COLUMN "timestamp" SET DEFAULT CURRENT_TIMESTAMP;

CREATE TABLE public.metrics_superv (
	name varchar NULL,
	"timestamp" timestamp NULL,
	f1_score varchar NULL,
	auc_score varchar NULL
);

ALTER TABLE public.metrics_superv ALTER COLUMN "timestamp" SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE public.metrics_superv ALTER COLUMN f1_score TYPE float4 USING f1_score::float4;
ALTER TABLE public.metrics_superv ALTER COLUMN auc_score TYPE float4 USING auc_score::float4;

ALTER TABLE public.metrics_superv ADD acc_score float4 NULL;
ALTER TABLE public.metrics_superv ADD precision_score float4 NULL;
ALTER TABLE public.metrics_superv ADD recall_score float4 NULL;
ALTER TABLE public.metrics_superv ADD tn int NULL;
ALTER TABLE public.metrics_superv ADD fp int NULL;
ALTER TABLE public.metrics_superv ADD fn int NULL;
ALTER TABLE public.metrics_superv ADD tp int NULL;

CREATE TABLE pod_resources (
    id SERIAL PRIMARY KEY,
    pod_name TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    cpu_millicores INT,
    memory_mib INT
);

CREATE TABLE pod_ip_conversations (
    id SERIAL PRIMARY KEY,
    pod_name TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    src_ip INET NOT NULL,
    dst_ip INET NOT NULL,
    bytes_src_to_dst BIGINT,
    bytes_dst_to_src BIGINT,
    total_bytes BIGINT
);