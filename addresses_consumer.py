import sys
import pgq

class AddressesConsumer(pgq.RemoteConsumer):
    def process_remote_batch(self, db, batch_id, ev_list, dst_db):
        for ev in ev_list:
            if ev.type == 'U':
               self.process_update(ev, db, dst_db) 

    def process_update(self, event, src_db, dst_db):
        old_addr, new_addr = event.data, event.extra1

        dst_db.cursor().execute('select get_lock()')
        src_db.cursor().execute('select get_lock()')

        src_db.cursor().execute('select update_address(%s, %s)', [old_addr, new_addr])
        dst_db.cursor().execute('select update_address(%s, %s)', [old_addr, new_addr])
        

AddressesConsumer('addresses_consumer', 'source_db', 'dest_db', sys.argv[1:]).start()
