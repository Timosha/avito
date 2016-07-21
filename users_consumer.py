import sys
import pgq

class UsersConsumer(pgq.RemoteConsumer):
    def process_remote_batch(self, db, batch_id, ev_list, dst_db):
        for ev in ev_list:
            if ev.type == 'I':
                self.process_insert(ev, db, dst_db)
            if ev.type == 'D':
                self.process_delete(ev, db, dst_db)
            if ev.type == 'U':
                self.process_update(ev, db, dst_db)

    def process_insert(self, event, src_db, dst_db):
        login, new_addr = event.data, event.extra1
        src_curs = src_db.cursor()
        dst_curs = dst_db.cursor()

        src_curs.execute('select get_lock()')
        dst_curs.execute('select get_lock()')

        src_curs.execute('select add_user_address(%s, %s)', [login, new_addr])
        dst_curs.execute('select add_address(%s)', [new_addr])

    def process_update(self, event, src_db, dst_db):
        login, old_addr, new_addr = event.data, event.extra1, event.extra2
        src_curs = src_db.cursor()
        dst_curs = dst_db.cursor()

        src_curs.execute('select get_lock()')
        dst_curs.execute('select get_lock()')

        src_curs.execute('select update_user_address(%s, %s, %s)', [login, old_addr, new_addr])
        src_curs.execute('select get_address_count(%s)', [old_addr])
        old_addr_count = src_curs.fetchone()[0]
        
        if old_addr_count == 0:
            dst_curs.execute('select update_address(%s, %s)', [old_addr, new_addr])
        else:
            dst_curs.execute('select add_address(%s)', [new_addr])

    def process_delete(self, event, src_db, dst_db):
        login, old_addr = event.data, event.extra1
        src_curs = src_db.cursor()
        dst_curs = dst_db.cursor()

        src_curs.execute('select get_lock()')
        dst_curs.execute('select get_lock()')

        src_curs.execute('select remove_address(%s, %s)', [login, old_addr])
        src_curs.execute('select get_address_count(%s)', [old_addr])
        old_addr_count = src_curs.fetchone()[0]
        if old_addr_count == 0:
            dst_curs.execute('select remove_address(%s)', [old_addr])


UsersConsumer('users_consumer', 'source_db', 'dest_db', sys.argv[1:]).start()
