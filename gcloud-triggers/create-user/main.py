import logging
import firebase_admin
from firebase_admin import credentials, firestore

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
cred = credentials.ApplicationDefault()  # Uses the default service account
firebase_admin.initialize_app(cred)
db = firestore.client()

# Function to create a new user document in Firestore
def create_user_document(uid, email):
    user_ref = db.collection('users').document(uid)
    if not user_ref.get().exists:
        user_ref.set({
            'email': email,
            'match_id': None,
            'rating': 1000,
            'searchingForMatch': False,
            'inMatch': False,
            'newMatch': False,
            'pot': 0
        })
        logger.info(f"Created document for user {email} with UID {uid}")
    else:
        logger.info(f"Document for user {email} with UID {uid} already exists")

# Cloud Function triggered by new user creation in Firebase Authentication
def handle_user_creation(event, context):
    uid = event["uid"]
    email = event["email"]
    logger.info(f"New user created with email: {email}")
    create_user_document(uid, email)
