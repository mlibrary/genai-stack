import os

import streamlit as st
import json

from langchain.docstore.document import Document
from langchain.chains import RetrievalQA
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.callbacks.base import BaseCallbackHandler
from langchain.vectorstores.neo4j_vector import Neo4jVector
from streamlit.logger import get_logger
from chains import (
    load_embedding_model,
    load_llm,
)

# load api key lib
from dotenv import load_dotenv

load_dotenv(".env")


url = os.getenv("NEO4J_URI")
username = os.getenv("NEO4J_USERNAME")
password = os.getenv("NEO4J_PASSWORD")
ollama_base_url = os.getenv("OLLAMA_BASE_URL")
embedding_model_name = os.getenv("EMBEDDING_MODEL")
llm_name = os.getenv("LLM")
# Remapping for Langchain Neo4j integration
os.environ["NEO4J_URL"] = url

logger = get_logger(__name__)


embeddings, dimension = load_embedding_model(
    embedding_model_name, config={"ollama_base_url": ollama_base_url}, logger=logger
)


class StreamHandler(BaseCallbackHandler):
    def __init__(self, container, initial_text=""):
        self.container = container
        self.text = initial_text

    def on_llm_new_token(self, token: str, **kwargs) -> None:
        self.text += token
        self.container.markdown(self.text)


llm = load_llm(llm_name, logger=logger, config={"ollama_base_url": ollama_base_url})


def main():
    st.header("📄Chat with your catalog file")

    # upload a your pdf file
    json_file = st.file_uploader("Upload your json")
    

    if json_file is not None:
        json_content = json.loads(json_file.read())
         
        documents = []
        for record in json_content["catalog"]:
          pc = record['title'][0] + ' ' + record.get("abstract", '')
          md = {
           "title": record["title"],
           "source": record["datastore"],
           "id": record["id"],
          }
          documents.append(Document(page_content=pc, metadata=md))

        # Store the chunks part in db (vector)
        vectorstore = Neo4jVector.from_documents(
            documents,
            url=url,
            username=username,
            password=password,
            embedding=embeddings,
            index_name="catalog_bot",
            node_label="CatalogRecord",
            pre_delete_collection=True,  # Delete existing PDF data
        )
        qa = RetrievalQA.from_chain_type(
            llm=llm, chain_type="stuff", retriever=vectorstore.as_retriever()
        )

        # Accept user questions/query
        query = st.text_input("Ask questions about your PDF file")

        if query:
            stream_handler = StreamHandler(st.empty())
            qa.run(query, callbacks=[stream_handler])


if __name__ == "__main__":
    main()
