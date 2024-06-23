import logging
import time

import firebase_admin
from firebase_admin import credentials, firestore

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Set the environment variable for Firestore (ensure this path is correct)
cred = credentials.Certificate("/opt/thisispoker/serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()


def end_match():
    try:
        # Get all user documents
        users_ref = db.collection('users')
        users = users_ref.stream()

        for user in users:
            user_data = user.to_dict()
            if not user_data.get('inMatch'):
                match_id = user_data['match_id']

                user_ref = users_ref.document(user.id)
                match_ref = db.collection('matches').document(match_id)
                match_doc = match_ref.get()
                if match_doc.exists:
                    user_doc = match_doc.get('player1') if match_doc.get('player1').get('id') == user.id else match_doc.get('player2')
                else:
                    user_doc = {'pot': 0}

                if user_data.get('newMatch'):
                    user_ref.update({
                        'match_id': '',
                        'searchingForMatch': True,
                        'pot': user_doc.get('pot')
                    })
                else:
                    user_ref.update({
                        'rating': user_data['rating'] + user_doc.get('pot'),
                        'match_id': '',
                        'searchingForMatch': False,
                        'pot': 0
                    })

                logger.info(f"Updated user document {user.id} to adjust rating/pot")

                # Delete the match document
                if match_doc.exists:
                    match_ref.delete()
                    logger.info(f"Deleted match with ID: {match_id}")

    except Exception as e:
        logger.error(f"Error in end_match: {e}", exc_info=True)


def monitor_match():
    logger.info("Monitoring matches...")
    try:
        while True:
            end_match()
            time.sleep(5)  # Check every 5 seconds
    except Exception as e:
        logger.error(f"Error in monitor_match: {e}", exc_info=True)


if __name__ == "__main__":
    monitor_match()
