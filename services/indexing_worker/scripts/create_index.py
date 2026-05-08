from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex,
    SimpleField,
    SearchableField,
    SearchField,
    SearchFieldDataType,
    VectorSearch,
    HnswAlgorithmConfiguration,
    HnswParameters,
    VectorSearchProfile,
    ScalarQuantizationCompression,                  # ✅ v12 name
    ScalarQuantizationParameters,                   # ✅ for int8
    RescoringOptions,                               # ✅ v12 — standalone class
    VectorSearchCompressionRescoreStorageMethod,    # ✅ v12 — enum for storage method
)
from azure.identity import DefaultAzureCredential
import os
from dotenv import load_dotenv

load_dotenv()  # Load environment variables from .env file

client = SearchIndexClient(
    endpoint=os.environ["SEARCH_ENDPOINT"],
    credential=DefaultAzureCredential()
)

index = SearchIndex(
    name=os.environ["SEARCH_INDEX_NAME"],
    fields=[
        SimpleField(
            name="id",
            type=SearchFieldDataType.STRING,
            key=True,
            filterable=True
        ),
        SimpleField(
            name="page_id",
            type=SearchFieldDataType.STRING,
            filterable=True,
            retrievable=True
        ),
        SimpleField(
            name="space_key",
            type=SearchFieldDataType.STRING,
            filterable=True,
            retrievable=True
        ),
        SimpleField(
            name="content_hash",
            type=SearchFieldDataType.STRING,
            retrievable=True
        ),
        SearchableField(
            name="title",
            type=SearchFieldDataType.STRING,
            retrievable=True
        ),
        SearchableField(
            name="content",
            type=SearchFieldDataType.STRING,
            retrievable=True,
            analyzer_name="en.microsoft"
        ),
        SimpleField(
            name="url",
            type=SearchFieldDataType.STRING,
            retrievable=True
        ),
        SearchField(
            name="content_vector",
            type="Collection(Edm.Single)", #Collection(Edm.Single) is the underlying Azure REST API type name for a collection of 32-bit floats used for vector fields.SearchFieldDataType.Collection(SearchFieldDataType.Single) was throwing an error for v12 .
            searchable=True,
            retrievable=False,
            stored=False,
            vector_search_dimensions=1536,
            vector_search_profile_name="vector-profile"
        ),
    ],
    vector_search=VectorSearch(
        algorithms=[
            HnswAlgorithmConfiguration(
                name="hnsw",
                parameters=HnswParameters(
                    m=4,
                    ef_construction=400,
                    ef_search=500,
                    metric="cosine"
                )
            )
        ],
        # compressions=[
        #     ScalarQuantizationCompression(
        #         name="scalar-quantization",
        #         parameters=ScalarQuantizationParameters(
        #             quantized_data_type="int8"
        #         ),
        #         rescoring_options=RescoringOptions(
        #             enable_rescoring=True,
        #             default_oversampling=10,
        #             rescore_storage_method=VectorSearchCompressionRescoreStorageMethod.PRESERVE_ORIGINALS
        #         )
        #     )
        # ],
        profiles=[
            VectorSearchProfile(
                name="vector-profile",
                algorithm_configuration_name="hnsw",
                #compression_name="scalar-quantization"
            )
        ]
    )
)

result = client.create_or_update_index(index)
print(f"Index '{result.name}' created successfully with scalar quantization")