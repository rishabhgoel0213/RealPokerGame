import logging
import time
import firebase_admin
from firebase_admin import credentials, firestore, auth

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
cred = credentials.Certificate("/opt/thisispoker/serviceAccountKey.json")  # Update with your own service account key
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

# Function to handle new user creation
def handle_user_creation(user):
    logger.info(f"New user created with email: {user.email}")
    create_user_document(user.uid, user.email)

# Listen for new user creation events
def listen_for_new_users():
    users = auth.list_users()
    for user in users.iterate_all():
        create_user_document(user.uid, user.email)

# Main function to start listening for new users
def main():
    logger.info("Listening for new users...")
    try:
        while True:
            listen_for_new_users()
            time.sleep(5)  # Check every 5 seconds
    except Exception as e:
        logger.error(f"Error in monitor_match: {e}", exc_info=True)

if __name__ == "__main__":
    main()
